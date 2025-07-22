import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _amountController = TextEditingController();

  List<String> currencies = [];
  String fromCurrency = "USD";
  String toCurrency = "EUR";
  String result = "";

  final String apiBaseUrl =
      "http://10.250.10.205:8000"; // Replace with your actual API base URL

  @override
  void initState() {
    super.initState();
    fetchCurrencies();
  }

  Future<void> fetchCurrencies() async {
    final response = await http.get(Uri.parse("$apiBaseUrl/currencies"));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        currencies = List<String>.from(data);
        fromCurrency = currencies.first;
        toCurrency = currencies[1];
      });
    } else {
      showError("Failed to fetch currencies");
    }
  }

  Future<void> convertCurrency() async {
    final String amountText = _amountController.text;
    if (amountText.isEmpty) {
      showError("Enter an amount");
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null) {
      showError("Invalid amount");
      return;
    }

    final response = await http.post(
      Uri.parse("$apiBaseUrl/convert"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "from": fromCurrency,
        "to": toCurrency,
        "amount": amount,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        result =
            "${data['amount']} ${data['from']} = ${data['converted']} ${data['to']}";
      });
    } else {
      final data = jsonDecode(response.body);
      showError(data['error'] ?? "Conversion failed");
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Currency Converter")),
      body: currencies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter Amount",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: buildDropdown(true)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.swap_horiz),
                      ),
                      Expanded(child: buildDropdown(false)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: convertCurrency,
                    child: const Text("Convert"),
                  ),
                  const SizedBox(height: 30),
                  Text(result, style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
    );
  }

  DropdownButton<String> buildDropdown(bool isFrom) {
    return DropdownButton<String>(
      isExpanded: true,
      value: isFrom ? fromCurrency : toCurrency,
      items: currencies
          .map((code) => DropdownMenuItem(value: code, child: Text(code)))
          .toList(),
      onChanged: (value) {
        setState(() {
          if (isFrom) {
            fromCurrency = value!;
          } else {
            toCurrency = value!;
          }
        });
      },
    );
  }
}
