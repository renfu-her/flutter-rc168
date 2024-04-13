import 'package:flutter/material.dart';
import 'package:rc168/main.dart';
import 'package:dio/dio.dart';
import 'package:rc168/pages/product_detail.dart';
import 'package:text_responsive/text_responsive.dart';
// import 'package:rc168/pages/shop/shop_page.dart';

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
  SortOption currentSortOption = SortOption.defaultSort;
  // int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    fetchCategory(currentSortOption);
  }

  void fetchCategory(SortOption sortOption) async {
    String sortParam;
    String orderParam;

    switch (sortOption) {
      case SortOption.defaultSort:
        sortParam = 'p.sort_order';
        orderParam = 'ASC';
        break;
      case SortOption.nameAsc:
        sortParam = 'pd.name';
        orderParam = 'ASC';
        break;
      case SortOption.nameDesc:
        sortParam = 'pd.name';
        orderParam = 'DESC';
        break;
      case SortOption.priceLowHigh:
        sortParam = 'p.price';
        orderParam = 'ASC';
        break;
      case SortOption.priceHighLow:
        sortParam = 'p.price';
        orderParam = 'DESC';
        break;
      case SortOption.modelAsc:
        sortParam = 'p.model';
        orderParam = 'ASC';
        break;
      case SortOption.modelDesc:
        sortParam = 'p.model';
        orderParam = 'DESC';
        break;
    }

    try {
      var response = await Dio().get(
        '${appUri}/gws_products&category_id=${widget.categoryId}&api_key=${apiKey}&order=$orderParam&sort=$sortParam',
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
      // print(e);
    }
  }

  String _sortOptionToString(SortOption sortOption) {
    switch (sortOption) {
      case SortOption.defaultSort:
        return '預設';
      case SortOption.nameAsc:
        return '名稱 (A-Z)';
      case SortOption.nameDesc:
        return '名稱 (Z-A)';
      case SortOption.priceLowHigh:
        return '價格 (低 > 高)';
      case SortOption.priceHighLow:
        return '價格 (高 > 低)';
      case SortOption.modelAsc:
        return '型號 (A-Z)';
      case SortOption.modelDesc:
        return '型號 (Z-A)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InlineTextWidget('產品列表 - ${widget.categoryName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Center(
          child: DropdownButton<SortOption>(
            value: currentSortOption,
            onChanged: (SortOption? newValue) {
              if (newValue != null) {
                setState(() {
                  currentSortOption = newValue;
                  fetchCategory(newValue);
                });
              }
            },
            items: SortOption.values.map((SortOption value) {
              return DropdownMenuItem<SortOption>(
                value: value,
                child: InlineTextWidget(_sortOptionToString(value)),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      productId: category.id,
                                    ),
                                  ),
                                );
                              },
                              child: Image.network(
                                category.thumb,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                InlineTextWidget(
                                  category.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                  // maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                InlineTextWidget(
                                  category.price,
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: ElevatedButton(
                              child: InlineTextWidget(
                                '加入購物車',
                                style: const TextStyle(fontSize: 18),
                              ),
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      productId: category.id,
                                    ),
                                  ),
                                );
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
        ),
      ]),
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
      thumb: '${imgUrl}' + json['thumb'],
      price: json['price'],
      href: json['href'],
    );
  }
}

enum SortOption {
  defaultSort,
  nameAsc,
  nameDesc,
  priceLowHigh,
  priceHighLow,
  modelAsc,
  modelDesc
}

Future<void> addToCart(String productId, int quantity) async {
  final formData = FormData.fromMap({
    'product_id': productId,
    'quantity': quantity,
  });

  print(productId);
  print(quantity);

  final addCartUrl =
      '${appUri}/gws_customer_cart/add&customer_id=${customerId}&api_key=${apiKey}';
  try {
    var response = await dio.post(
      addCartUrl,
      data: formData,
    );

    // 检查响应或进行后续操作
    if (response.data['message'][0]['msg_status'] == true) {
      // 成功添加后的操作
    }
  } on DioException catch (e) {
    // 错误处理
    print(e);
  }
}
