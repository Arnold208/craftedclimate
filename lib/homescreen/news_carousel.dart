import 'package:flutter/material.dart';

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('Crafted News', style: TextStyle(fontSize: 17),),
      ),
      body: const SingleChildScrollView(
        child: Padding(padding: EdgeInsets.all(8), child: Column(
          children: [
            
          ],
        ),),
      ),
    );
  }
}