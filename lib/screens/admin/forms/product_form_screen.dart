import 'package:appbanquanao/models/product_variant.dart';
import 'package:appbanquanao/services/category_service.dart';
import 'package:appbanquanao/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../models/product.dart';
import '../../../models/category.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'dart:io' as io;

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _colorController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isUploadingImage = false;

  XFile? _selectedImage;

  final List<String> _sizes = ['S', 'M', 'L', 'XL'];
  final List<String> _colors = [
    'Đỏ',
    'Xanh',
    'Vàng',
    'Đen',
    'Trắng',
    'Be.',
    'Nâu',
  ];

  List<String> _selectedSizes = [];
  Map<String, TextEditingController> _sizeStockControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    if (widget.product != null) {
      _populateForm(widget.product!);
    }
  }

  void _populateForm(Product p) {
    _nameController.text = p.name;
    _descriptionController.text = p.description;
    _priceController.text = p.price.toString();
    _imageUrlController.text = p.imageUrl;
    _selectedCategoryId = p.categoryId.toString();
    _selectedSizes = p.variants.map((v) => v.size).toList();
    _colorController.text = p.variants.isNotEmpty ? p.variants.first.color : '';

    for (final variant in p.variants) {
      _sizeStockControllers[variant.size] = TextEditingController(
        text: variant.stock.toString(),
      );
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await CategoryService().fetchCategories();
      setState(() => _categories = categories);
    } catch (e) {
      debugPrint('Lỗi khi tải danh mục: $e');
    }
  }

  Future<void> _pickImageAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _selectedImage = picked;
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await ProductService().uploadImage(picked);
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        if (imageUrl != null) {
          _imageUrlController.text = imageUrl;
        } else {
          _showSnackBar('Không thể upload ảnh', Colors.red);
        }
      });
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showSnackBar('Lỗi khi upload ảnh', Colors.red);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnackBar('Vui lòng chọn danh mục', Colors.red);
      return;
    }
    if (_imageUrlController.text.isEmpty) {
      _showSnackBar('Bạn chưa chọn ảnh sản phẩm', Colors.red);
      return;
    }
    if (_selectedSizes.isEmpty) {
      _showSnackBar('Vui lòng chọn ít nhất 1 kích thước', Colors.red);
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null) {
      _showSnackBar('Giá không hợp lệ', Colors.red);
      return;
    }

    for (final size in _selectedSizes) {
      final text = _sizeStockControllers[size]?.text ?? '';
      if (text.isEmpty) {
        _showSnackBar('Tồn kho size $size không được để trống', Colors.red);
        return;
      }
      if (int.tryParse(text) == null) {
        _showSnackBar('Tồn kho size $size phải là số hợp lệ', Colors.red);
        return;
      }
    }

    setState(() => _isLoading = true);

    final variants = _selectedSizes
        .map(
          (size) => ProductVariant(
            id: '0',
            size: size,
            color: _colorController.text.trim(),
            stock: int.parse(_sizeStockControllers[size]!.text),
          ),
        )
        .toList();

    final product = Product(
      id: widget.product?.id ?? 0, // nullable int
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: price,
      stock: 0,
      imageUrl: _imageUrlController.text.trim(),
      categoryId: int.parse(_selectedCategoryId!), // ép String -> int
      variants: variants,
    );

    try {
      debugPrint('Product to save: ${jsonEncode(product.toJson())}');
      final success = widget.product == null
          ? await ProductService().addProduct(product)
          : await ProductService().updateProduct(product);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        _showSnackBar('🎉 Đã lưu sản phẩm thành công', Colors.green);
        Navigator.of(context).pop(true);
      } else {
        _showSnackBar('Không thể lưu sản phẩm', Colors.red);
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi lưu sản phẩm: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Đã xảy ra lỗi khi lưu sản phẩm', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Widget buildImagePreview(XFile pickedImage) {
    return kIsWeb
        ? FutureBuilder<Uint8List>(
            future: pickedImage.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            },
          )
        : Image.file(io.File(pickedImage.path), fit: BoxFit.cover);
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ảnh sản phẩm *'),
        const SizedBox(height: 8),
        Stack(
          children: [
            GestureDetector(
              onTap: _pickImageAndUpload,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedImage != null
                      ? buildImagePreview(_selectedImage!)
                      : (_imageUrlController.text.isNotEmpty
                            ? Image.network(
                                _imageUrlController.text,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.add_a_photo, size: 40)),
                ),
              ),
            ),
            if (_isUploadingImage)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            if (_selectedImage != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = null;
                      _imageUrlController.clear();
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Vui lòng chọn $label' : null,
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (v) {
            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập $label';
            return null;
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_nameController, 'Tên sản phẩm *'),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Mô tả *', maxLines: 3),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Danh mục *',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c.id.toString(),
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng chọn danh mục'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _priceController,
                'Giá (VND) *',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              MultiSelectDialogField(
                items: _sizes
                    .map((e) => MultiSelectItem<String>(e, e))
                    .toList(),
                title: const Text('Kích thước'),
                buttonText: const Text('Chọn kích thước *'),
                initialValue: _selectedSizes,
                searchable: true,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                listType: MultiSelectListType.CHIP,
                onConfirm: (values) {
                  setState(() {
                    final oldControllers =
                        Map<String, TextEditingController>.from(
                          _sizeStockControllers,
                        );
                    _selectedSizes = List<String>.from(values);

                    _sizeStockControllers.clear();

                    for (final size in _selectedSizes) {
                      if (oldControllers.containsKey(size)) {
                        // Giữ lại controller cũ để giữ tồn kho đã nhập
                        _sizeStockControllers[size] = oldControllers[size]!;
                      } else {
                        // Tạo controller mới cho size mới chọn
                        _sizeStockControllers[size] = TextEditingController();
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedSizes.isNotEmpty)
                Column(
                  children: _selectedSizes
                      .map(
                        (size) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildTextField(
                            _sizeStockControllers[size]!,
                            'Tồn kho cho size $size *',
                            inputType: TextInputType.number,
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Màu sắc *',
                value: _colors.contains(_colorController.text)
                    ? _colorController.text
                    : null,
                items: _colors,
                onChanged: (v) =>
                    setState(() => _colorController.text = v ?? ''),
              ),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    : Text(
                        widget.product == null
                            ? 'Thêm sản phẩm'
                            : 'Cập nhật sản phẩm',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
