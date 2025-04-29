import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sattle_me/features/home/rental_service/pages/favorite_page.dart';
import 'package:sattle_me/features/home/rental_service/pages/listing_detalis_page.dart';
import 'package:sattle_me/features/home/rental_service/pages/message_screen.dart';

/// RentalListPage: Displays all rental listings.
class RentalListPage extends StatefulWidget {
  final List<Map<String, String>> favoriteRentals;
  const RentalListPage({Key? key, required this.favoriteRentals})
    : super(key: key);

  @override
  _RentalListPageState createState() => _RentalListPageState();
}

class _RentalListPageState extends State<RentalListPage> {
  final int _selectedIndex = 0;
  Set<Map<String, String>> favoriteRentals = {};

  @override
  void initState() {
    super.initState();
    favoriteRentals = widget.favoriteRentals.toSet();
  }

  void _toggleFavorite(Map<String, String> rental) {
    setState(() {
      if (favoriteRentals.contains(rental)) {
        favoriteRentals.remove(rental);
      } else {
        favoriteRentals.add(rental);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rental Listings")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("rentalListings")
                .orderBy("timestamp", descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading listings: ${snapshot.error.toString()}",
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final listings = snapshot.data?.docs;
          if (listings == null || listings.isEmpty) {
            return const Center(child: Text("No listings available"));
          }
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listingData =
                  listings[index].data() as Map<String, dynamic>;
              String title = listingData["name"] ?? "No title";
              String address = listingData["address"] ?? "No address";
              String price = listingData["price"] ?? "";
              List<dynamic> imageUrls = listingData["imageUrls"] ?? [];
              String imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : "";

              Map<String, String> rental = {
                "title": title,
                "address": address,
                "price": price,
                "image": imageUrl,
              };
              bool isFavorite = favoriteRentals.contains(rental);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ListingDetailPage(doc: listings[index]),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child:
                                imageUrl.isNotEmpty
                                    ? Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      height: 200,
                                      color: Colors.grey,
                                      child: const Center(
                                        child: Text("No image available"),
                                      ),
                                    ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 30,
                              ),
                              onPressed: () => _toggleFavorite(rental),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              price,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
