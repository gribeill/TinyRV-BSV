int doubler(int a) {
	return 2*a;
}

int main() {
	int a = 4;
	int b = 7;
	int c = 0;
	int z = 0;
	for (int i = 0; i < 3; i++){
		c += i+doubler(a)+b;
	}
	z = c;
	asm volatile("ecall");
	return 0;
}