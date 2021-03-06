import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';

import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:loader_search_bar/loader_search_bar.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/book.dart';
import '../screens/details_screen.dart';
import '../screens/details2_screen.dart';
import '../screens/result_screen.dart';

List<Book> books = [];
List<Card> cards = [];

class HomePage extends StatefulWidget {

  final List<Book> data;
  HomePage({this.data});

  @override
  HomePageState createState() {
    return new HomePageState();
  }
}

class HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Content(data: widget.data),
    );
  }
}

Future<List<Book>> fetchFrontPage(int page) async {
  http.Response response = await http.get("$frontPage?page=$page");
  List decoded = json.decode(response.body)["result"];
  decoded.forEach((book) {
    books.add(new Book.fromJson(book));
  });
  return books;
}

Future<List<Book>> fetchQuery(String query, int page) async {
  http.Response response = await http.get("$baseUrl/api/galleries/search?query=$query");
  List decoded = json.decode(response.body)["result"];
  decoded.forEach((book) {
    books.add(new Book.fromJson(book));
  });
  return books;
}

class Content extends StatefulWidget {

  final List<Book> data;
  Content({this.data});

  @override
  _ContentState createState() => new _ContentState();
}

class _ContentState extends State<Content> {

  ScrollController scrollController;
  int page = 1;

  @override
  void initState() {
    //books = widget.data;
    fetchFrontPage(1).then((books){
      if(mounted) {
        setState(() {
          books = books;          
        });
      }
    });
    scrollController = new ScrollController()..addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (scrollController.position.extentAfter == 0.0) {
      setState(() {
        page += 1;
        fetchFrontPage(page);
      });
    }
  }

  List<Widget> _createBookCards(List<Book> books){
    cards = new List();
    books.forEach((Book book){
      Widget card = new Card(
        child: new GridTile(
          footer: new GridTileBar(
            backgroundColor: Colors.black54,
            title: Text(
              book.title.pretty,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            )
          ),
          child: new GestureDetector(
            child: new FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: "$tUrl/galleries/${book.mediaId}/thumb.${book.images.thumbnail.t}",
              fit: BoxFit.cover,
            ),
            onTap: (){
              Navigator.push(context, new MaterialPageRoute(builder: (context) => new DetailsScreen(book: book,)));
            },
          ),
        )
      );
      cards.add(card);
    });
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return books.isEmpty ? 
    Center(child: new CircularProgressIndicator()) 
    : 
    new Container(
      child: new Scrollbar(
        child: CustomScrollView(
          primary: false,
          controller: scrollController,
          slivers: <Widget>[
            new SliverAppBar(
              title: new Text("nHentai App"),
              centerTitle: true,
              floating: true,
              snap: true,
              forceElevated: true,
              bottom: new AppBar(
                primary: false,
                title: new TextField(
                  decoration: new InputDecoration(
                    prefixIcon: new Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Search doujins",
                  ),
                  onSubmitted: (String query) {
                    Navigator.push(context, new MaterialPageRoute(builder: (context) => new ResultScreen(query: query,)));
                  },
                ),
              )
            ),
            new SliverPadding(
              padding: const EdgeInsets.all(5.0),
              sliver: new SliverStaggeredGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 2.0,
                mainAxisSpacing: 2.0,
                children: _createBookCards(books),
                staggeredTiles: new List.generate(books.length, (i) => new StaggeredTile.count(1, 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
