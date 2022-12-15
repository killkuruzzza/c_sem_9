using System;
using static System.Console;

Clear();
Write("Введите N: ");
int n=int.Parse(ReadLine());

WriteLine(PrintNumbers(n));

string PrintNumbers(int end)
{
    if (end == 1)
    {
        Console.WriteLine(1);
        return "1";
    }
    string s = PrintNumbers(end - 1) + ' ' + end.ToString();
    Console.WriteLine(s);
    return (s);
}
// **Задача 65:**Задайте значения M и N.
//  Напишите программу, которая выведет все
//   натуральные числа в промежутке от M до N.

// M = 1; N = 5. -> "1, 2, 3, 4, 5"
// M = 4; N = 8. -> "4, 5, 6, 7, 8"