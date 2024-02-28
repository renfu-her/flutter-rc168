import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/category/category_detail_page.dart';
import 'package:rc168/responsive_text.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    // fetchCategories();
  }

  Future<List<Category>> fetchCategories() async {
    // try {
    var response = await dio.get('${appUri}/gws_categories&api_key=${apiKey}');

    if (response.statusCode == 200) {
      List<dynamic> categoryJson = response.data['categories'];
      return categoryJson.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load category');
    }
    // } catch (e) {
    //   throw Exception('Error: Failed to load category');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('分類'),
      ),
      body: FutureBuilder<List<Category>>(
        future: fetchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No categories found"));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var category = snapshot.data![index];
                var imagePath = category.image.isNotEmpty
                    ? '${imgUrl}' + category.image
                    : 'assets/images/no_image.png';

                return ListTile(
                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.cover, // 控制圖片如何佔滿容器
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/no_image.png', // 預設圖片
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  title: Container(
                    // 確保文字和圖片高度一致
                    alignment: Alignment.centerLeft,
                    height: 65,
                    child: ResponsiveText(
                      category.name,
                      fontSize: 18,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailPage(
                          categoryId: category.id,
                          categoryName: category.name,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Category {
  final String id;
  final String name;
  final String image;

  Category({required this.id, required this.name, this.image = ''});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
        id: json['category_id'] as String,
        name: json['name'] as String,
        image: json['image'] as String? ?? '');
  }
}
