namespace SolveModularEquation_UnitTests {

    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Math;

    // Helper operation that asserts that the oracle indeed implements the given function.
    operation AssertOracleImplementsFunction(
        searchSpaceSize : Int,
        classicalFunction : (Int -> Bool),
        markingOracle : ((Qubit[], Qubit) => Unit is Adj)
    ) : Unit {
        let N = BitSizeI(searchSpaceSize - 1);
        use (inputs, output) = (Qubit[N], Qubit());

        // Iterate over all possible input bit strings (as integers).
        for x in 0 .. searchSpaceSize - 1 {
            // Convert the integer into a bit string (little-endian encoding).
            let bits = IntAsBoolArray(x, N);
            within {
                // Prepare the input state.
                ApplyPauliFromBitString(PauliX, true, bits, inputs);
            } apply {
                // Apply the oracle to calculate the output for this input.
                markingOracle(inputs, output);
            }

            // Check that the result matches the expected (calculated using the given function).
            let expectedResult = classicalFunction(x);
            let actualResult = MResetZ(output) == One;
            Fact(actualResult == expectedResult,
                $"Test failed for input {bits}: expected function value {expectedResult}, actual oracle evaluation result {actualResult}");

            // Check that the inputs were not modified
            Fact(MeasureInteger(LittleEndian(inputs)) == 0, 
                $"Test failed for input {bits}: the input states were modified");
        }
    }


    // A function that checks whether x solves the equation ax + b = 0 (mod 11) classically.
    function IsEquationSolutionClassical(a : Int, b: Int, c : Int, x : Int) : Bool {
        return (a * x + b) % c == 0;
    }


    // Operations marked with @Test attribute are executed as Q# unit tests.
    @Test("QuantumSimulator")
    operation FindEquationSolutionTests() : Unit {
        for (a, b, c) in [(1, 2, 3), (1, 3, 4), (4, 6, 7), (5, 8, 9), (10, 1, 11)] {
            Message($"Testing equation {a}x + {b} = 0 (mod {c})...");
            // Call the helper operation with the classical function and the quantum oracle instantiated for (a, b).
            AssertOracleImplementsFunction(c, 
                IsEquationSolutionClassical(a, b, c, _), 
                SolveModularEquation.IsEquationSolution(a, b, c, _, _));
            Message("   Test passed!");
        }
    }
}