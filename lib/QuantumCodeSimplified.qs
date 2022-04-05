namespace SolveModularEquationSimplified {

    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;

    open SolveModularEquation;

    /// # Summary
    /// Marking oracle that checks whether the integer x written in the register
    /// is a solution to the equation x + b = 0 (mod 4).
    operation IsEquationSolutionSimplified(b : Int, x : Qubit[], target : Qubit) : Unit is Adj {
        within {
            // Add b to x (mod 4).
            // Since we only have 2 bits, do increments manually.
            // Lower bit (x[0]):
            if b % 2 == 1 {
                X(x[0]);
                ControlledOnInt(0, X)([x[0]], x[1]);
            }

            // Higher bit (x[1]):
            if b >= 2 {
                X(x[1]);
            }
        } apply {
            // Check whether the result is 0.
            ControlledOnInt(0, X)(x, target);
        }
    }


    /// # Summary
    /// A greatly simplified Grover's search implementation.
    /// Solves an equation of the form x + b = 0 (mod 4).
    operation FindEquationSolutionSimplified(b : Int) : Result[] {
        let c = 4;
        Message($"Solving equation x + {b} = 0 (mod {c})");

        // Calculate the number of iterations.
        let nIterations = Round(PI() / 4.0 / ArcSin(Sqrt(1.0 / IntAsDouble(c))) - 0.5);
        Message($"Using {nIterations} iteration(s).");

        // Instantiate the marking oracle for equation ax + b = 0 (mod c).
        let markingOracle = IsEquationSolutionSimplified(b, _, _);

        // Use a more efficient state preparation routine.
        let meanPrep = ApplyToEachA(H, _);

        // Run Grover's search for this oracle.
        let groversResult = RunGroversSearchForGivenProblem(markingOracle, meanPrep, c, nIterations);

        return groversResult;
    }
}
