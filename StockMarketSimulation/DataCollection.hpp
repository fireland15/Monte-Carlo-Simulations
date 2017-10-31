#pragma once

#include <istream>
#include <string>
#include <list>
#include <iostream>
#include <sstream>

std::list<std::string> split(std::string& str);

enum Type : unsigned int {
	String,
	Number,
	DateTime
};

class DataObject {
protected:
	Type _type;
public:
	virtual bool equals(DataObject& other) = 0;
	Type getType() { return _type; }
};

class String : protected DataObject {
private:
	std::string _value;
public:
	String(std::string& value) {
		_value = value;
		_type = Type::String;
	}

	virtual bool equals(DataObject& other) {
		if (_type != other.getType()) return false;
		return _value == ((String&)other)._value;
	}
};

class Number : protected DataObject {
private:
	enum Precision : unsigned int {
		Double,
		Float,
		Integer
	};

	double _dvalue;
	float _fvalue;
	int _ivalue;
	Precision _precision;

public:
	Number(double value) {
		_dvalue = value;
		_type = Type::Number;
		_precision = Precision::Double;
	}

	Number(float value) {
		_fvalue = value;
		_type = Type::Number;
		_precision = Precision::Float;
	}
	Number(int value) {
		_ivalue = value;
		_type = Type::Number;
		_precision = Precision::Integer;
	}

	virtual bool equals(DataObject& other) {
		if (_type != other.getType()) return false;
		
		auto o = (Number&)other;

		if (_precision == Precision::Double && o._precision == Precision::Double)
			return _dvalue == o._dvalue;
		else if (_precision == Precision::Double && o._precision == Precision::Float)
			return _dvalue == o._fvalue;
		else if (_precision == Precision::Double && o._precision == Precision::Integer)
			return _dvalue == o._ivalue;
		else if (_precision == Precision::Float && o._precision == Precision::Double)
			return _fvalue == o._dvalue;
		else if (_precision == Precision::Float && o._precision == Precision::Float)
			return _fvalue == o._fvalue;
		else if (_precision == Precision::Float && o._precision == Precision::Integer)
			return _fvalue == o._ivalue;
		else if (_precision == Precision::Integer && o._precision == Precision::Double)
			return _ivalue == o._dvalue;
		else if (_precision == Precision::Integer && o._precision == Precision::Float)
			return _ivalue == o._fvalue;
		else if (_precision == Precision::Integer && o._precision == Precision::Integer)
			return _ivalue == o._ivalue;
	}
};

class DateTime : protected DataObject {
private:
	int _year;
	int _month;
	int _day;
	int _hour;
	int _minute;
	int _second;

public:
	DateTime(int year, int month, int day, int hour = 0, int minute = 0, int second = 0) {
		_year = year;
		_month = month;
		_day = day;
		_hour = hour;
		_minute = minute;
		_second = second;
		_type = Type::DateTime;
	}
};

class DataCollection {
private:
	std::list<DataObject> _data;

public:
	DataCollection() { }

	static DataCollection LoadFromCsvFormattedStream(std::istream& s) {
		std::string line;
		while (std::getline(s, line)) {
			if (line.length() == 0)
				continue;
			
			auto x = split(line);

			for (auto xx : x) {
				DataValue<std::string> dv(xx);
				std::cout << dv.toString() << std::endl;
			}
		}
	}
};

std::list<std::string> split(std::string& str) {
	const char delim = ',';
	std::list<std::string> s;

	size_t start = 0;
	size_t end = 0;
	while ((end = str.find(delim, start)) != std::string::npos) {
		std::string token = str.substr(start, end - start);
		s.push_back(token);
		start = end += 2;
	}

	return s;
}