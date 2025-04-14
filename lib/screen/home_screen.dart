import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import '../provider/inventory_provider.dart';
import '../model/sale_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'Mingguan'; // Default: Mingguan
  final List<String> _periods = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];
  DateTime? _startDate;
  DateTime? _endDate;

  // Warna dari logo WarungkuPintar
  final Color primaryColor = const Color(0xFF2E7D32); // Hijau tua
  final Color secondaryColor = const Color(0xFFFBC02D); // Kuning

  // State untuk melacak bar yang disentuh
  int? _touchedGroupIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<InventoryProvider>(context, listen: false);

    provider.loadItems();
    provider.loadSales();
    // Tambah delay untuk memastikan data dari Firestore sudah masuk
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              secondary: secondaryColor,
              onSecondary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
              titleLarge: TextStyle(color: Colors.black),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Fungsi untuk format Rupiah dengan pemisah ribuan
  String _formatRupiah(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  // Fungsi untuk format label sumbu Y dengan istilah Indonesia
  String _formatLabelY(double value) {
    if (value >= 1000000000000) {
      return '${(value / 1000000000000).toStringAsFixed(1)}T';
    } else if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}Jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}Rb';
    } else {
      return value.toInt().toString();
    }
  }

  List<BarChartGroupData> _getSalesTrend(InventoryProvider provider) {
    final now = DateTime.now();
    final defaultStart = now.subtract(const Duration(days: 30));
    final start = _startDate ?? defaultStart;
    final end = _endDate ?? now;

    // Pastikan start tidak lebih besar dari end
    if (start.isAfter(end)) {
      return [];
    }

    // Tentukan periode dan kelompokkan data
    final salesByPeriod = <String, double>{};
    final barGroups = <BarChartGroupData>[];
    int groupCount;
    List<DateTime> periodDates = [];

    switch (_selectedPeriod) {
      case 'Harian':
        final daysInPeriod = end.difference(start).inDays + 1;
        groupCount = daysInPeriod;
        for (int i = 0; i < daysInPeriod; i++) {
          final currentDate = start.add(Duration(days: i));
          periodDates.add(currentDate);
          final key = DateFormat('yyyy-MM-dd').format(currentDate);
          salesByPeriod[key] = 0;
        }
        for (var sale in provider.sales) {
          if (sale.date != null &&
              sale.date!.isAfter(start.subtract(const Duration(days: 1))) &&
              sale.date!.isBefore(end.add(const Duration(days: 1)))) {
            final saleDate =
                DateTime(sale.date!.year, sale.date!.month, sale.date!.day);
            final key = DateFormat('yyyy-MM-dd').format(saleDate);
            salesByPeriod[key] =
                (salesByPeriod[key] ?? 0) + (sale.totalPrice ?? 0);
          }
        }
        break;

      case 'Mingguan':
        final daysInPeriod = end.difference(start).inDays + 1;
        groupCount = (daysInPeriod / 7).ceil();
        for (int i = 0; i < groupCount; i++) {
          final weekStart = start.add(Duration(days: i * 7));
          if (weekStart.isAfter(end)) break;
          periodDates.add(weekStart);
          final key = DateFormat('yyyy-MM-dd').format(weekStart);
          salesByPeriod[key] = 0;
        }
        for (var sale in provider.sales) {
          if (sale.date != null &&
              sale.date!.isAfter(start.subtract(const Duration(days: 1))) &&
              sale.date!.isBefore(end.add(const Duration(days: 1)))) {
            final saleDate =
                DateTime(sale.date!.year, sale.date!.month, sale.date!.day);
            final daysSinceStart = saleDate.difference(start).inDays;
            final weekIndex = (daysSinceStart / 7).floor();
            final weekStart = start.add(Duration(days: weekIndex * 7));
            if (weekStart.isAfter(end)) continue;
            final key = DateFormat('yyyy-MM-dd').format(weekStart);
            salesByPeriod[key] =
                (salesByPeriod[key] ?? 0) + (sale.totalPrice ?? 0);
          }
        }
        break;

      case 'Bulanan':
        final startMonth = DateTime(start.year, start.month, 1);
        final endMonth = DateTime(end.year, end.month, 1);
        groupCount = ((endMonth.year - startMonth.year) * 12 +
                endMonth.month -
                startMonth.month) +
            1;
        for (int i = 0; i < groupCount; i++) {
          final currentMonth =
              DateTime(startMonth.year, startMonth.month + i, 1);
          if (currentMonth.isAfter(endMonth)) break;
          periodDates.add(currentMonth);
          final key = DateFormat('yyyy-MM').format(currentMonth);
          salesByPeriod[key] = 0;
        }
        for (var sale in provider.sales) {
          if (sale.date != null &&
              sale.date!.isAfter(start.subtract(const Duration(days: 1))) &&
              sale.date!.isBefore(end.add(const Duration(days: 1)))) {
            final saleDate = DateTime(sale.date!.year, sale.date!.month, 1);
            final key = DateFormat('yyyy-MM').format(saleDate);
            salesByPeriod[key] =
                (salesByPeriod[key] ?? 0) + (sale.totalPrice ?? 0);
          }
        }
        break;

      case 'Tahunan':
        final startYear = DateTime(start.year, 1, 1);
        final endYear = DateTime(end.year, 1, 1);
        groupCount = (endYear.year - startYear.year) + 1;
        for (int i = 0; i < groupCount; i++) {
          final currentYear = DateTime(startYear.year + i, 1, 1);
          if (currentYear.isAfter(endYear)) break;
          periodDates.add(currentYear);
          final key = DateFormat('yyyy').format(currentYear);
          salesByPeriod[key] = 0;
        }
        for (var sale in provider.sales) {
          if (sale.date != null &&
              sale.date!.isAfter(start.subtract(const Duration(days: 1))) &&
              sale.date!.isBefore(end.add(const Duration(days: 1)))) {
            final saleDate = DateTime(sale.date!.year, 1, 1);
            final key = DateFormat('yyyy').format(saleDate);
            salesByPeriod[key] =
                (salesByPeriod[key] ?? 0) + (sale.totalPrice ?? 0);
          }
        }
        break;

      default:
        groupCount = 0;
    }

    // Buat bar chart untuk setiap grup
    for (int i = 0; i < periodDates.length; i++) {
      final date = periodDates[i];
      String key;
      switch (_selectedPeriod) {
        case 'Harian':
          key = DateFormat('yyyy-MM-dd').format(date);
          break;
        case 'Mingguan':
          key = DateFormat('yyyy-MM-dd').format(date);
          break;
        case 'Bulanan':
          key = DateFormat('yyyy-MM').format(date);
          break;
        case 'Tahunan':
          key = DateFormat('yyyy').format(date);
          break;
        default:
          key = '';
      }
      final sales = salesByPeriod[key] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sales,
              color: _touchedGroupIndex == i
                  ? secondaryColor // Highlight dengan warna kuning saat disentuh
                  : primaryColor, // Warna default (hijau tua)
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        // Hitung lebar chart berdasarkan jumlah grup
        int groupCount;
        double labelInterval;
        final now = DateTime.now();
        final defaultStart = now.subtract(const Duration(days: 30));
        final start = _startDate ?? defaultStart;
        final end = _endDate ?? now;

        switch (_selectedPeriod) {
          case 'Harian':
            groupCount = end.difference(start).inDays + 1;
            labelInterval = groupCount > 5 ? 3 : 1;
            break;
          case 'Mingguan':
            final daysInPeriod = end.difference(start).inDays + 1;
            groupCount = (daysInPeriod / 7).ceil();
            labelInterval = groupCount > 5 ? 2 : 1;
            break;
          case 'Bulanan':
            final startMonth = DateTime(start.year, start.month, 1);
            final endMonth = DateTime(end.year, end.month, 1);
            groupCount = ((endMonth.year - startMonth.year) * 12 +
                    endMonth.month -
                    startMonth.month) +
                1;
            labelInterval = groupCount > 5 ? 3 : 1;
            break;
          case 'Tahunan':
            final startYear = DateTime(start.year, 1, 1);
            final endYear = DateTime(end.year, 1, 1);
            groupCount = (endYear.year - startYear.year) + 1;
            labelInterval = groupCount > 5 ? 2 : 1;
            break;
          default:
            groupCount = 7;
            labelInterval = 1;
        }
        final chartWidth = groupCount * 70.0; // Lebar per grup 70 piksel

        // Hitung nilai maksimum untuk sumbu Y dari data penjualan
        double rawMaxY = 0;
        final barGroups = _getSalesTrend(provider);
        if (barGroups.isNotEmpty) {
          rawMaxY = barGroups
              .map((group) => group.barRods[0].toY)
              .reduce((a, b) => a > b ? a : b);
        }
        rawMaxY = rawMaxY == 0 ? 10000.0 : rawMaxY;

        // Bulatkan maxY ke kelipatan tertentu untuk skala yang rapi
        double maxY;
        if (rawMaxY <= 10000) {
          maxY = (rawMaxY / 1000).ceil() * 1000;
        } else if (rawMaxY <= 100000) {
          maxY = (rawMaxY / 5000).ceil() * 5000;
        } else if (rawMaxY <= 1000000) {
          maxY = (rawMaxY / 50000).ceil() * 50000;
        } else {
          maxY = (rawMaxY / 500000).ceil() * 500000;
        }

        // Tambah padding atas 40% agar bar tidak menempel pada batas atas
        maxY = maxY * 1.4;

        // Tentukan jumlah label sumbu Y (misalnya 5 label)
        const int yLabelCount = 5;
        final yInterval = maxY / (yLabelCount - 1);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(
                  child: Lottie.asset(
                    'assets/loading.json',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                "Penjualan Hari Ini",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatRupiah(provider.todaySales),
                                style: TextStyle(
                                    fontSize: 24, color: primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Dari",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _selectDate(context, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: primaryColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _startDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_startDate!)
                                            : 'Pilih Tanggal',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _startDate != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Sampai",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _selectDate(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: primaryColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _endDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_endDate!)
                                            : 'Pilih Tanggal',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _endDate != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Periode:",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              DropdownButton<String>(
                                value: _selectedPeriod,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedPeriod = newValue!;
                                  });
                                },
                                items: _periods.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Tren Penjualan",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 40,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(yLabelCount, (index) {
                                  final value =
                                      yInterval * (yLabelCount - 1 - index);
                                  String label = _formatLabelY(value);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      label,
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.end,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: chartWidth + 100, // Padding kanan
                                  child: BarChart(
                                    BarChartData(
                                      maxY: maxY,
                                      barGroups: barGroups,
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              final date =
                                                  _getDateForIndex(index);
                                              String label;
                                              switch (_selectedPeriod) {
                                                case 'Harian':
                                                  label =
                                                      '${date.day}/${date.month}';
                                                  break;
                                                case 'Mingguan':
                                                  label =
                                                      '${date.day}/${date.month}';
                                                  break;
                                                case 'Bulanan':
                                                  label = DateFormat('MMM')
                                                      .format(date);
                                                  break;
                                                case 'Tahunan':
                                                  label = '${date.year}';
                                                  break;
                                                default:
                                                  label = '';
                                              }
                                              return Text(
                                                label,
                                                style: const TextStyle(
                                                    fontSize: 10),
                                                textAlign: TextAlign.center,
                                              );
                                            },
                                            reservedSize: 30,
                                            interval: labelInterval,
                                          ),
                                        ),
                                        leftTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                      ),
                                      gridData: FlGridData(show: false),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        handleBuiltInTouches: true,
                                        touchExtraThreshold:
                                            const EdgeInsets.only(
                                          left: 20,
                                          right: 30,
                                          top: 20,
                                          bottom: 20,
                                        ),
                                        touchCallback: (FlTouchEvent event,
                                            barTouchResponse) {
                                          setState(() {
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                barTouchResponse == null ||
                                                barTouchResponse.spot == null) {
                                              _touchedGroupIndex = null;
                                              return;
                                            }
                                            _touchedGroupIndex =
                                                barTouchResponse
                                                    .spot!.touchedBarGroupIndex;
                                            final sales =
                                                barGroups[_touchedGroupIndex!]
                                                    .barRods[0]
                                                    .toY;
                                            print(
                                                'Touched bar index: $_touchedGroupIndex, Sales: $sales');
                                          });
                                        },
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor: (_) => primaryColor,
                                          tooltipMargin: 10,
                                          tooltipPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                          getTooltipItem: (group, groupIndex,
                                              rod, rodIndex) {
                                            print(
                                                'Tooltip for groupIndex: $groupIndex, value: ${rod.toY}');
                                            return BarTooltipItem(
                                              _formatRupiah(rod.toY),
                                              // Gunakan format Rupiah lengkap
                                              const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Stok Kritis",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      provider.criticalStock.isEmpty
                          ? const Center(child: Text("Tidak ada stok kritis"))
                          : SizedBox(
                              height: 200,
                              child: ListView.builder(
                                itemCount: provider.criticalStock.length,
                                itemBuilder: (context, index) {
                                  final item = provider.criticalStock[index];
                                  return ListTile(
                                    title: Text(item.name ?? ''),
                                    subtitle: Text(
                                      "Sisa: ${item.quantity ?? 0} ${item.stockPrediction != null ? '- ${item.stockPrediction}' : ''}",
                                    ),
                                    trailing: const Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                    ),
                                  );
                                },
                              ),
                            ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        );
      },
    );
  }

  DateTime _getDateForIndex(int index) {
    final now = DateTime.now();
    final defaultStart = now.subtract(const Duration(days: 30));
    final start = _startDate ?? defaultStart;

    switch (_selectedPeriod) {
      case 'Harian':
        return start.add(Duration(days: index));
      case 'Mingguan':
        return start.add(Duration(days: index * 7));
      case 'Bulanan':
        return DateTime(start.year, start.month + index, 1);
      case 'Tahunan':
        return DateTime(start.year + index, 1, 1);
      default:
        return start;
    }
  }
}
