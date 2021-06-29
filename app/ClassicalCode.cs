namespace RecoverISBNNumber 
{
    using System;
    using System.Linq;
    using Microsoft.Quantum.Simulation.Simulators;
    using Microsoft.Quantum.Simulation.Core;
    using SolveModularEquation;

    /// <summary>
    /// The classical driver for the quantum computation.
    /// </summary>
    public class ClassicalHost
    {
        static void Main(string[] args) 
        {
            // Define the ISBN-10 number to look for.
            string isbn = "051199?001";

            // Classical pre-processing: convert the ISBN number into the parameters
            // taken by the quantum code: an equation of the form ax + b = 0 (mod c).
            long c = 11;
            int missingIndex = isbn.IndexOf('?');
            long a = 10 - missingIndex;

            long b = 0;
            for (int i = 0; i < 10; ++i) {
                if (isbn[i] != '?') {
                    b += (10 - i) * (isbn[i] - '0');
                }
            }
            b %= 11;

            // Run the quantum code to solve the equation.
            using var simulator = new QuantumSimulator();
            Result[] result = FindEquationSolution.Run(simulator, a, b, c).Result.ToArray();

            // Classical post-processing: format the resulting ISBN.
            // Convert an array of measurement results into a number (little-endian encoding).
            int recoveredDigit = 0;
            for (int i = result.Length - 1; i >= 0; --i) {
                recoveredDigit = recoveredDigit * 2 + (result[i] == Result.One ? 1 : 0);
            }

            string finalIsbn = isbn.Replace('?', Convert.ToChar('0' + recoveredDigit));
            Console.WriteLine($"The recovered ISBN is {finalIsbn}");
        }
    }
}