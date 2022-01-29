namespace SolveModularEquation {

    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;


    /// # Summary
    /// Marking oracle that checks whether the integer x written in the register
    /// is a solution to the equation ax + b = 0 (mod c).
    operation IsEquationSolution(a : Int, b : Int, c : Int, x : Qubit[], target : Qubit) : Unit is Adj {
        // Start with the value x in the register, and modify it in place.
        within {
            // Multiply it by a (mod c).
            MultiplyByModularInteger(a, c, LittleEndian(x));
            // Add to it b (mod c).
            IncrementByModularInteger(b, c, LittleEndian(x));
        } apply {
            // Check whether the result is 0.
            ControlledOnInt(0, X)(x, target);
        }
    }


    /// # Summary
    /// Apply a marking oracle as a phase oracle using phase kickback trick.
    operation ApplyMarkingOracleAsPhaseOracle(
        markingOracle : ((Qubit[], Qubit) => Unit is Adj),
        register : Qubit[]
    ) : Unit is Adj {
        use minus = Qubit();
        within {
            X(minus);
            H(minus);
        } apply {
            markingOracle(register, minus);
        }
    }


    /// # Summary
    /// Prepare an equal superposition of all basis states from 0 to (searchSpaceSize - 1), inclusive.
    operation PrepareTheMean(register : Qubit[], searchSpaceSize : Int) : Unit is Adj {
        PrepareArbitraryStateD(ConstantArray(searchSpaceSize, 1.0), LittleEndian(register));
    }


    /// # Summary
    /// Generic operation that runs Grover search for the problem described as a marking oracle.
    operation RunGroversSearchForGivenProblem(
        markingOracle : ((Qubit[], Qubit) => Unit is Adj), 
        meanStatePrep : ((Qubit[]) => Unit is Adj),
        searchSpaceSize : Int, 
        nIterations : Int
    ) : Result[] {
        // Allocate the qubits to use in the search algorithm.
        use register = Qubit[BitSizeI(searchSpaceSize - 1)];

        // Convert the marking oracle to a phase oracle using partial application.
        let phaseOracle = ApplyMarkingOracleAsPhaseOracle(markingOracle, _);

        // Prepare an equal superposition of all basis states from 0 to (searchSpaceSize - 1), inclusive
        // (this way we don't need to implement the check for the answer being < c in the oracle itself).
        meanStatePrep(register);
        
        // Run iterations of Grover's search.
        for _ in 1 .. nIterations {
            // Apply the phase oracle.
            phaseOracle(register);
            
            // Perform reflection around the mean.
            within {
                Adjoint meanStatePrep(register);
                ApplyToEachA(X, register);
            } apply {
                Controlled Z(Most(register), Tail(register));
            }
        }

        // Measure and return the results of Grover's search.
        return MultiM(register);
    }


    /// # Summary
    /// Solves equation of the form ax + b = 0 (mod c).
    operation FindEquationSolution(a : Int, b : Int, c : Int) : Result[] {
        Message($"Solving equation {a}x + {b} = 0 (mod {c})");

        // Calculate the number of iterations.
        let nIterations = Round(PI() / 4.0 / ArcSin(Sqrt(1.0 / IntAsDouble(c))) - 0.5);
        Message($"Using {nIterations} iterations.");

        // Instantiate the marking oracle for equation ax + b = 0 (mod c).
        let markingOracle = IsEquationSolution(a, b, c, _, _);

        // Check whether c is a power of 2; if it is, use a more efficient state prep routine.
        let meanPrep = PrepareTheMean(_, c);

        // Run Grover's search for this oracle.
        let groversResult = RunGroversSearchForGivenProblem(markingOracle, meanPrep, c, nIterations);

        // Return the raw results for the caller to interpret.
        return groversResult;
    }
}

