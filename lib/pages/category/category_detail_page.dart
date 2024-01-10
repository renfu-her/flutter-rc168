import 'package:flutter/material.dart';
import 'package:rc168/main.dart';
import 'package:dio/dio.dart';

class CategoryDetailPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  const CategoryDetailPage(
      {super.key, required this.categoryId, required this.categoryName});

  @override
  _CategoryDetailPageState createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  List<Category> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategory();
  }

  void fetchCategory() async {
    try {
      var response = await Dio().get(
        '${app_url}/index.php?route=extension/module/api/gws_products&category_id=${widget.categoryId}&api_key=$api_key&order=DESC&sort=pd.name',
      );
      var data = response.data['products'] as List;
      setState(() {
        categories = data.map((json) => Category.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('產品列表 - ${widget.categoryName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // 跳轉到產品詳情頁面的邏輯
                          },
                          child: Image.network(
                            category.thumb,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              category.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              category.price,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          child: Text('加入購物車'),
                          onPressed: () {
                            // 加入購物車的邏輯
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class Category {
  final String id;
  final String name;
  final String thumb;
  final String price;
  final String href;

  Category(
      {required this.id,
      required this.name,
      required this.thumb,
      required this.price,
      required this.href});

  // 從 JSON 數據解析創建產品模型的工廠構造函數
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['product_id'],
      name: json['name'],
      thumb: '${img_url}' + json['thumb'],
      price: json['price'],
      href: json['href'],
    );
  }
}
