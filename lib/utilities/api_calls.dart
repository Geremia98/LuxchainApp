import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lux_chain/utilities/api_models.dart';

Future<List<WalletWatch>> getUserWalletWatches(int userID) async {
  try {
    // Effettua la chiamata per ottenere le azioni associate all'utente
    final response = await http.get(
      Uri.parse('https://luxchain-flame.vercel.app/api/wallet/watches/$userID'),
    );

    if (response.statusCode == 200) {
      print('entro 1');
      final List<dynamic> data = jsonDecode(response.body);
      print(data);
      return data.map((e) => WalletWatch.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load user shares');
    }
  } catch (e) {
    print('entro 2');
    throw Exception('Error retrieving user watches: $e');
  }
}
