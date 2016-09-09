import std.stdio;

class Array(Type) {
	this(int len)
	{
		data.length = len;
	}
	void Insert(Type obj)
	{
		if(numObjs >= (data.length - 1))
			data.length = data.length * 2;
		data[numObjs++] = obj;
	}
	Type Get(int i)
	{
		fwritef(stderr, "%d\n", i);
		return data[i];
	}
	int GetLength()
	{
		return numObjs;
	}
	void Shrink()
	{
		data.length = numObjs;
	}
	void Empty()
	{
		data.length = 0;
	}
	Type[] data;
	int numObjs;
}
