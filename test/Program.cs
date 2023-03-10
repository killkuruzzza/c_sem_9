void a(int b){
    if (b >= 1){
        a(b - 1);
        Console.Write($"{b} ");
    }
}
a(7);