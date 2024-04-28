import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/category/category_detail_page.dart';
import 'package:text_responsive/text_responsive.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<List<Category>> fetchCategories() async {
    var dio = Dio();
    Response response = await dio
        .get('${appUri}/gws_appservice/allCategories&api_key=${apiKey}');
    if (response.statusCode == 200) {
      List<dynamic> data = response.data['categories'];
      print(data);
      return data.map((category) => Category.fromJson(category)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分類'),
      ),
      body: FutureBuilder<List<Category>>(
        future: fetchCategories(),
        builder:
            (BuildContext context, AsyncSnapshot<List<Category>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Category> categories = snapshot.data ?? [];
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                Category category = categories[index];
                return SizedBox(
                    height: 80,
                    child: ListTile(
                      title: Text(category.name),
                      leading: ClipOval(
                        child: Image.network(
                          category.image,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailPage(
                              categoryId: category.column,
                              categoryName: category.name,
                            ),
                          ),
                        );
                      },
                    ));
              },
            );
          }
        },
      ),
    );
  }
}

class Category {
  final String name;
  final String column;
  final String href;
  final String image;
  final List<dynamic> children;

  Category({
    required this.name,
    required this.column,
    required this.href,
    required this.image,
    required this.children,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String,
      children: json['children'] as List<dynamic>,
      column: json['column'] as String,
      href: json['href'] as String,
      image: json['image'] as String,
    );
  }
}
