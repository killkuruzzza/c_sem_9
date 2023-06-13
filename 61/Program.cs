using System;
using static System.Console;

Clear();

Write("Введите нужное количество строк треугольника Паскаля: ");
int rows = int.Parse(ReadLine());
PrintTriangle(rows);

//Функция вывода треугольника
void PrintTriangle(int n)
{
    //Цикл для перебора строк треугольника
    for (int i = 0; i < n; i++)
    {
        // создаём после каждой строки n-i отступов от левой стороны консоли, чем ниже строка, тем меньше отступ
        for (int c = 0; c <= (n - i); c++) {
            Write("  ");
        }
        for (int c = 0; c <= i; c++)
        {
            Write("   "); // создаём пробелы между элементами треугольника
            Write(factorial(i) / (factorial(c) * factorial(i - c))); //формула вычисления элементов треугольника
        }
        WriteLine(); // после каждой строки с числами отступаем две пустые строчки
    }
}
//Функция для подсчета факториала
float factorial(int n)
{
    float x = 1;
    for (int i = 1; i <= n; i++)
    {
        x *= i;
    }
    return x;
}