using System;
using static System.Console;
Clear();
Write("Введите M: ");
int m = int.Parse(ReadLine());
Write("Введите N: ");
int n = int.Parse(ReadLine());

WriteLine(PrintNumbers(m, n));

string PrintNumbers(int start, int end)
{
    if (start == end)
        return start.ToString();
    return (start + " " + PrintNumbers(start + 1, end));
}
/***Задача 67:** Напишите программу, 
которая будет принимать на вход число и возвращать сумму его цифр.

453 -> 12

45 -> 9*/