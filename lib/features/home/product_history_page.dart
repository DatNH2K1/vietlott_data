import 'package:flutter/material.dart';
import 'package:vietlott_data/features/home/widgets/draw_card.dart';
import 'package:vietlott_data/models/lottery_draw_model.dart';
import 'package:vietlott_data/repositories/lottery_repository.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';

class ProductHistoryPage extends StatefulWidget {
  const ProductHistoryPage({required this.productName, super.key});

  final String productName;

  @override
  State<ProductHistoryPage> createState() => _ProductHistoryPageState();
}

class _ProductHistoryPageState extends State<ProductHistoryPage> {
  final LotteryRepository _lotteryRepo = LotteryRepository();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageOffset = 0;
  String? _errorMessage;
  List<LotteryDrawModel> _draws = [];
  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHistory(isInitial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory({bool isInitial = false}) async {
    if (isInitial) {
      if (_isLoadingMore) return;
      setState(() {
        _isLoading = _draws.isEmpty;
        _errorMessage = null;
        _pageOffset = 0;
        _hasMore = true;
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final newDraws = await _lotteryRepo.getDraws(
        widget.productName,
        limit: _pageSize,
        offset: _pageOffset,
      );

      if (mounted) {
        setState(() {
          if (isInitial) {
            _draws = newDraws;
            _pageOffset = newDraws.length;
          } else {
            _draws.addAll(newDraws);
            _pageOffset += newDraws.length;
          }
          if (newDraws.length < _pageSize) {
            _hasMore = false;
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '$e';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  String _getDisplayName(String product) {
    return product.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final displayName = _getDisplayName(widget.productName);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${localizations.errorOccurred}$_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _loadHistory(isInitial: true),
                      icon: const Icon(Icons.refresh),
                      label: Text(localizations.retry),
                    ),
                  ],
                ),
              ),
            )
          : _draws.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '${localizations.noResults}$displayName',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadHistory(isInitial: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _draws.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _draws.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final draw = _draws[index];
                  return DrawCard(
                    draw: draw,
                    productName: widget.productName,
                    index: index,
                  );
                },
              ),
            ),
    );
  }
}
