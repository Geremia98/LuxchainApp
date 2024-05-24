import 'package:flutter/material.dart';
import 'package:lux_chain/screens/wallet_specs_screen.dart';
import 'package:lux_chain/screens/watch_screen.dart';
import 'package:lux_chain/utilities/api_calls.dart';
import 'package:lux_chain/utilities/api_models.dart';
import 'package:lux_chain/utilities/firestore.dart';
import 'package:lux_chain/utilities/models.dart';
import 'package:lux_chain/utilities/size_config.dart';
import 'package:lux_chain/utilities/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletScreen extends StatefulWidget {
  static const String id = 'WalletScreen';

  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<List<WalletWatch>> futureWatches;
  late Future<WalletData> futureWalletData;

  @override
  void initState() {
    super.initState();
    futureWatches = Future.value([]);
    futureWalletData = Future.value(const WalletData(
        inShares: 0,
        liquidity: 0,
        rate: 0)); // Initialize with empty WalletData
    _initializeData();
  }

  void _initializeData() async {
    Future<SharedPreferences> userFuture = getUserData();
    SharedPreferences user = await userFuture;

    // Assume that you have a specific key in SharedPreferences
    int userId = user.getInt('accountid') ?? 0;

    setState(() {
      futureWatches = getUserWalletWatches(userId);
      futureWalletData = getWalletData(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double height = SizeConfig.screenH!;
    double width = SizeConfig.screenW!;
    double contributiNetti = 715300.00;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
            padding: EdgeInsets.only(
                right: width * 0.05, left: width * 0.05, top: height * 0.01),
            child: FutureBuilder<WalletData>(
              future: futureWalletData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData) {
                  WalletData walletData = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Text(
                            'Wallet value',
                            style: TextStyle(fontSize: width * 0.05),
                          ),
                          SizedBox(
                            width: width * 0.02,
                          ),
                          const Icon(Icons.visibility),
                        ],
                      ),
                      SizedBox(
                        height: height * 0.01,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WalletSpecsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatAmountFromDouble(
                                    walletData.inShares + walletData.liquidity),
                                style: TextStyle(
                                    color: Colors.black87,
                                    height: 1,
                                    fontSize: width * 0.1,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                width: width * 0.01,
                              ),
                              Text(
                                '€',
                                style: TextStyle(
                                  fontSize: width * 0.06,
                                  height: 1,
                                ),
                              ),
                              Expanded(
                                  child: SizedBox(
                                width: width * 0.01,
                              )),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(3)),
                                    color: walletData.rate > 0
                                        ? Colors.lightGreen
                                        : Colors.red),
                                child: Text('${walletData.rate}%'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'Contributi netti: ${formatAmountFromDouble(contributiNetti)} €',
                        style: TextStyle(fontSize: width * 0.04),
                      ),
                      SizedBox(
                        height: height * 0.01,
                      ),
                      Text(
                        'In shares: ${formatAmountFromDouble(walletData.inShares)} €',
                        style: TextStyle(fontSize: width * 0.04),
                      ),
                      Text(
                        'Liquidity: ${formatAmountFromDouble(walletData.liquidity)} €',
                        style: TextStyle(fontSize: width * 0.04),
                      ),
                      SizedBox(
                        height: height * 0.04,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: FutureBuilder<List<WalletWatch>>(
                                future: futureWatches,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasData) {
                                    List<WalletWatch> walletWatches =
                                        snapshot.data!;
                                    return Column(
                                      children: walletWatches.map(
                                        (watch) {
                                          return CustomBottomBigCard(
                                            watchID: watch.watchId,
                                            screenWidth: width,
                                            walletWatch: watch,
                                            imgUrl:
                                                getDownloadURL(watch.imageuri),
                                          );
                                        },
                                      ).toList(),
                                    );
                                  } else if (snapshot.hasError) {
                                    // Gestisci il caso in cui si verifica un errore
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    // Gestisci il caso in cui non ci sono dati disponibili
                                    return const SizedBox(); // Placeholder widget when no data is available
                                  }
                                })),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  // Gestisci il caso in cui si verifica un errore
                  return Text('Error: ${snapshot.error}');
                } else {
                  // Gestisci il caso in cui non ci sono dati disponibili
                  return const SizedBox(); // Placeholder widget when no data is available
                }
              },
            )),
      ),
    );
  }
}

class CustomBottomBigCard extends StatelessWidget {
  const CustomBottomBigCard({
    Key? key,
    required this.watchID,
    required this.screenWidth,
    required this.walletWatch,
    required this.imgUrl,
  }) : super(key: key);

  final int watchID;
  final double screenWidth;
  final WalletWatch walletWatch;
  final Future<String> imgUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(WatchScreen.id,
          arguments: Watch(
              watchId: walletWatch.watchId,
              condition: walletWatch.condition,
              numberOfShares: walletWatch.numberOfShares,
              initialPrice: walletWatch.initialPrice,
              actualPrice: walletWatch.actualPrice,
              dialcolor: walletWatch.dialcolor,
              year: walletWatch.year,
              imageuri: walletWatch.imageuri,
              description: walletWatch.description,
              modelTypeId: walletWatch.modelTypeId,
              modelType: walletWatch.modelType)),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black26,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(3, 3), // Shadow position
            ),
          ],
          borderRadius: const BorderRadius.all(Radius.circular(7)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Column(
                children: [
                  FutureBuilder<String>(
                    future: imgUrl,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasData) {
                        return ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(7)),
                          child: Image.network(
                            snapshot.data!,
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return const Text('Image not found');
                      }
                    },
                  ),
                  SizedBox(height: screenWidth * 0.05),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                      color: (walletWatch.increaseRate > 0)
                          ? Colors.lightGreen
                          : Colors.red,
                    ),
                    child: Text('${walletWatch.increaseRate}%'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  walletWatch.modelType.model.brandname,
                  style: TextStyle(
                    color: Colors.black38,
                    height: 1,
                    fontSize: screenWidth * 0.05,
                    fontFamily: 'Bebas',
                  ),
                ),
                Text(
                  walletWatch.modelType.model.modelname,
                  style: TextStyle(
                    color: Colors.black87,
                    height: 1,
                    fontSize: screenWidth * 0.055,
                    fontFamily: 'Bebas',
                  ),
                ),
                Text('Reference: ${walletWatch.modelType.reference}'),
                SizedBox(height: screenWidth * 0.02),
                Text(
                    'Owned Shares: ${walletWatch.owned}/${walletWatch.numberOfShares}'),
                Text(
                    'Initial Price: ${formatAmountFromDouble(walletWatch.initialPrice)}€'),
                Text(
                    'Actual Price: ${formatAmountFromDouble(walletWatch.actualPrice)}€'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
