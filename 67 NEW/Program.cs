//Напишите программу, которая будет принимать на вход 
//число и возвращать сумму его цифр.
using System;
using static System.Console;


Clear();
Write("Введите число: ");
int m = int.Parse(ReadLine());

WriteLine($"{m}->{SumNumbers(m)}");
int sum = 0;
while (m > 0)
{
    sum += m % 10; // <=> sum = sum + m % 10
    m /= 10; // <=> m = m / 10
}
WriteLine($"{sum}");


int SumNumbers(int number)
{
    if (number == 0)
        return 0;
    return number % 10 + SumNumbers(number / 10);
}
// Console.Clear();
// Console.Write("Введите A: ");
// int A = int.Parse(Console.ReadLine());
// Console.Write("Введите B: ");
// int B = int.Parse(Console.ReadLine());
// Console.WriteLine(PowNumbers(A, B));

// int PowNumbers(int a, int b)
// {
//     if (b == 0)
//     {
//         return 1;
//     }
//     a *= PowNumbers(a, b - 1);
//     return (a);
// }





// **Задача 69:**Напишите программу,
//  которая на вход принимает два числа A и B,
//   и возводит число А в целую степень B с помощью рекурсии.

// A = 3; B = 5-> 243(3⁵)

// A = 2; B = 3-> 8