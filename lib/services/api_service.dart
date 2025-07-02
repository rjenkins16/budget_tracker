// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';
import '../models/goal.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<List<Expense>> getExpenses() async {
    final response = await http.get(Uri.parse('$baseUrl/expenses'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Expense.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load expenses");
    }
  }

  static Future<void> addExpense(Expense expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(expense.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to add expense");
    }
  }

  static Future<List<Goal>> getGoals() async {
    final response = await http.get(Uri.parse('$baseUrl/goals'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((g) => Goal.fromJson(g)).toList();
    } else {
      throw Exception("Failed to load goals");
    }
  }

  static Future<void> addGoal(Goal goal) async {
    final response = await http.post(
      Uri.parse('$baseUrl/goals'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(goal.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to add goal");
    }
  }

  static Future<Map<String, dynamic>> getCalendar() async {
    final response = await http.get(Uri.parse('$baseUrl/calendar'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load calendar data");
    }
  }
}
