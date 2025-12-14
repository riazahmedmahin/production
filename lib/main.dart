import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Textile Production Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ProductionTrackerApp(),
    );
  }
}

// ==================== DATA MODELS ====================

class LineData {
  int lineNumber;
  int unitNumber;
  int target;
  int achieve;
  int balance;
  String notes;

  LineData({
    required this.lineNumber,
    required this.unitNumber,
    required this.target,
    this.achieve = 0,
    this.balance = 0,
    this.notes = '',
  });
}

class HourlyUpdate {
  int hour;
  List<LineData> lines = [];
  String notes;

  HourlyUpdate({
    required this.hour,
    this.notes = '',
  });

  int getTotalInput() {
    return lines.fold(0, (sum, line) => sum + line.achieve);
  }

  int getTotalBalance() {
    return lines.fold(0, (sum, line) => sum + line.balance);
  }
}

class StyleItem {
  final String styleId;
  final String styleCode;
  final String color;
  final String itemType; // Long Pant, Short Pant, etc
  int totalQuantity;

  // Department-wise hourly updates
  Map<String, List<HourlyUpdate>> departmentHourlyUpdates = {
    'Cutting': [],
    'Sewing': [],
    'Finishing': [],
  };

  StyleItem({
    required this.styleId,
    required this.styleCode,
    required this.color,
    required this.itemType,
    this.totalQuantity = 0,
  });
}

class PurchaseOrder {
  final String poNumber;
  final String factory;
  List<StyleItem> styles = [];

  PurchaseOrder({
    required this.poNumber,
    required this.factory,
  });
}

class ProductionReport {
  String reportId;
  String poNumber;
  String styleId;
  String department; // Cutting, Sewing, Finishing
  String date;
  int totalInput = 0;
  int totalBalance = 0;
  int totalProduced = 0;
  int totalQcPass = 0;
  Map<int, HourlyUpdate> hourlyData = {}; // Hour -> Update

  ProductionReport({
    required this.reportId,
    required this.poNumber,
    required this.styleId,
    required this.department,
    required this.date,
  });

  int getDailyTotal() {
    return hourlyData.values.fold(0, (sum, h) => sum + h.getTotalInput());
  }
}

// ==================== MAIN APP ====================

class ProductionTrackerApp extends StatefulWidget {
  const ProductionTrackerApp({super.key});

  @override
  State<ProductionTrackerApp> createState() => _ProductionTrackerAppState();
}

class _ProductionTrackerAppState extends State<ProductionTrackerApp> {
  int selectedTabIndex = 0;

  // Sample data
  late List<PurchaseOrder> purchaseOrders;
  late List<ProductionReport> productionReports;

  @override
  void initState() {
    super.initState();
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Create Winner Jeans PO
    final winnerPO = PurchaseOrder(
      poNumber: '9087687',
      factory: 'Winner Jeans - Major',
    );

    // Add styles
    final style1 = StyleItem(
      styleId: 'WIN-001',
      styleCode: 'IUO9809UIKJ',
      color: 'Blue',
      itemType: 'Long Pant',
      totalQuantity: 5000,
    );

    final style2 = StyleItem(
      styleId: 'WIN-002',
      styleCode: 'IUO9809UIKJ',
      color: 'Red',
      itemType: 'Short Pant',
      totalQuantity: 3000,
    );

    winnerPO.styles.addAll([style1, style2]);
    purchaseOrders = [winnerPO];
    productionReports = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Textile Production Tracker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Navigation
          Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('Orders', 0),
                  _buildTab('Production', 1),
                  _buildTab('Reports', 2),
                ],
              ),
            ),
          ),
          Expanded(
            child: selectedTabIndex == 0
                ? OrdersListView(
                    purchaseOrders: purchaseOrders,
                    onStyleSelected: _showStyleDetails,
                  )
                : selectedTabIndex == 1
                    ? ProductionTrackingView(
                        purchaseOrders: purchaseOrders,
                        onReportAdded: (report) {
                          setState(() => productionReports.add(report));
                        },
                      )
                    : DailyReportsView(reports: productionReports),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.deepPurple : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.deepPurple : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showStyleDetails(StyleItem style, PurchaseOrder po) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StyleDetailsSheet(
        style: style,
        po: po,
      ),
    );
  }
}

// ==================== ORDERS VIEW ====================

class OrdersListView extends StatelessWidget {
  final List<PurchaseOrder> purchaseOrders;
  final Function(StyleItem, PurchaseOrder) onStyleSelected;

  const OrdersListView({
    super.key,
    required this.purchaseOrders,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...purchaseOrders.map((po) => _buildPOCard(context, po)).toList(),
        ],
      ),
    );
  }

  Widget _buildPOCard(BuildContext context, PurchaseOrder po) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PO: ${po.poNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      po.factory,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${po.styles.length} Styles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...po.styles.map((style) => _buildStyleTile(context, style, po)),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleTile(BuildContext context, StyleItem style, PurchaseOrder po) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${style.color} - ${style.itemType}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                'Code: ${style.styleCode} | Qty: ${style.totalQuantity}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => onStyleSelected(style, po),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Details'),
          ),
        ],
      ),
    );
  }
}

// ==================== STYLE DETAILS SHEET ====================

class StyleDetailsSheet extends StatelessWidget {
  final StyleItem style;
  final PurchaseOrder po;

  const StyleDetailsSheet({
    super.key,
    required this.style,
    required this.po,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${style.color} - ${style.itemType}'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: '✂️ Cutting'),
              Tab(text: '🧵 Sewing'),
              Tab(text: '🔨 Finishing'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DepartmentTrackingView(
              style: style,
              po: po,
              department: 'Cutting',
            ),
            DepartmentTrackingView(
              style: style,
              po: po,
              department: 'Sewing',
            ),
            DepartmentTrackingView(
              style: style,
              po: po,
              department: 'Finishing',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DEPARTMENT TRACKING ====================

class DepartmentTrackingView extends StatefulWidget {
  final StyleItem style;
  final PurchaseOrder po;
  final String department;

  const DepartmentTrackingView({
    super.key,
    required this.style,
    required this.po,
    required this.department,
  });

  @override
  State<DepartmentTrackingView> createState() => _DepartmentTrackingViewState();
}

class _DepartmentTrackingViewState extends State<DepartmentTrackingView> {
  late List<HourlyUpdate> hourlyUpdates;

  @override
  void initState() {
    super.initState();
    hourlyUpdates =
        widget.style.departmentHourlyUpdates[widget.department] ?? [];
    if (hourlyUpdates.isEmpty) {
      for (int i = 1; i <= 8; i++) {
        final hourUpdate = HourlyUpdate(hour: i);
        // Add sample lines
        hourUpdate.lines.addAll([
          LineData(
            lineNumber: 1,
            unitNumber: 1,
            target: 100,
          ),
          LineData(
            lineNumber: 2,
            unitNumber: 1,
            target: 100,
          ),
        ]);
        hourlyUpdates.add(hourUpdate);
      }
      widget.style.departmentHourlyUpdates[widget.department] = hourlyUpdates;
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalInput = hourlyUpdates.fold(0, (sum, h) => sum + h.getTotalInput());
    int totalBalance = hourlyUpdates.fold(0, (sum, h) => sum + h.getTotalBalance());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildSummaryRow('Total Input (All Hours)', '$totalInput Pcs', Colors.blue),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      'Total Balance', '$totalBalance Pcs', Colors.orange),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      'Total Quantity', '${widget.style.totalQuantity} Pcs', Colors.purple),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hourly Line Tracking',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...hourlyUpdates.asMap().entries.map((entry) {
            int index = entry.key;
            HourlyUpdate update = entry.value;
            return _buildHourCard(index, update);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHourCard(int index, HourlyUpdate update) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hour ${update.hour}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Total: ${update.getTotalInput()} Pcs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...update.lines.asMap().entries.map((lineEntry) {
              return _buildLineDetail(update, lineEntry.value);
            }).toList(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showHourlyUpdateDialog(update),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Hour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineDetail(HourlyUpdate hour, LineData line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Line-${line.lineNumber} Unit-${line.unitNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                'Target: ${line.target} | Achieve: ${line.achieve}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Balance: ${line.balance}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHourlyUpdateDialog(HourlyUpdate update) {
    showDialog(
      context: context,
      builder: (context) => HourlyUpdateEditorDialog(
        hourlyUpdate: update,
        department: widget.department,
        onSave: () {
          setState(() {});
        },
      ),
    );
  }
}

// ==================== PRODUCTION TRACKING ====================

class ProductionTrackingView extends StatefulWidget {
  final List<PurchaseOrder> purchaseOrders;
  final Function(ProductionReport) onReportAdded;

  const ProductionTrackingView({
    super.key,
    required this.purchaseOrders,
    required this.onReportAdded,
  });

  @override
  State<ProductionTrackingView> createState() => _ProductionTrackingViewState();
}

class _ProductionTrackingViewState extends State<ProductionTrackingView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Production Update',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...widget.purchaseOrders.map((po) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PO: ${po.poNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...po.styles.map((style) {
                  return _buildQuickUpdateCard(po, style);
                }).toList(),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickUpdateCard(PurchaseOrder po, StyleItem style) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${style.color} - ${style.itemType}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDepartmentReport(po, style, 'Cutting'),
                    child: const Text('Cutting'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDepartmentReport(po, style, 'Sewing'),
                    child: const Text('Sewing'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _showDepartmentReport(po, style, 'Finishing'),
                    child: const Text('Finishing'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentReport(
      PurchaseOrder po, StyleItem style, String department) {
    showDialog(
      context: context,
      builder: (context) => DailyReportDialog(
        po: po,
        style: style,
        department: department,
        onAdd: widget.onReportAdded,
      ),
    );
  }
}

// ==================== DAILY REPORTS ====================

class DailyReportsView extends StatelessWidget {
  final List<ProductionReport> reports;

  const DailyReportsView({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Production Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (reports.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No reports yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...reports.groupBy((r) => '${r.poNumber}-${r.styleId}').entries.map(
              (entry) {
                return _buildStyleReportCard(entry.value);
              },
            ).toList(),
        ],
      ),
    );
  }

  Widget _buildStyleReportCard(List<ProductionReport> reports) {
    final firstReport = reports.first;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PO: ${firstReport.poNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Date: ${firstReport.date}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...reports.map((report) {
              return Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.department,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildReportStat(
                            'Total Input', '${report.getDailyTotal()} Pcs'),
                        _buildReportStat(
                            'Total Balance', '${report.totalBalance} Pcs'),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}

// ==================== DAILY REPORT DIALOG ====================

class DailyReportDialog extends StatefulWidget {
  final PurchaseOrder po;
  final StyleItem style;
  final String department;
  final Function(ProductionReport) onAdd;

  const DailyReportDialog({
    super.key,
    required this.po,
    required this.style,
    required this.department,
    required this.onAdd,
  });

  @override
  State<DailyReportDialog> createState() => _DailyReportDialogState();
}

class _DailyReportDialogState extends State<DailyReportDialog> {
  @override
  Widget build(BuildContext context) {
    final hourlyUpdates = widget.style.departmentHourlyUpdates[widget.department] ?? [];
    final totalInput = hourlyUpdates.fold(0, (sum, h) => sum + h.getTotalInput());
    final totalBalance = hourlyUpdates.fold(0, (sum, h) => sum + h.getTotalBalance());

    return AlertDialog(
      title: Text(
          '${widget.department} Report - ${widget.style.color} ${widget.style.itemType}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Daily Input:'),
                      Text(
                        '$totalInput Pcs',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Balance:'),
                      Text(
                        '$totalBalance Pcs',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hourly Breakdown:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...hourlyUpdates.map((h) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hour ${h.hour}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Total: ${h.getTotalInput()} Pcs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...h.lines.map((line) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'L${line.lineNumber}U${line.unitNumber}: Tgt=${line.target} Ach=${line.achieve} Bal=${line.balance}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            final report = ProductionReport(
              reportId: DateTime.now().toString(),
              poNumber: widget.po.poNumber,
              styleId: widget.style.styleId,
              department: widget.department,
              date: DateFormat('dd/MMMM/yy').format(DateTime.now()),
            );
            
            // Add hourly data to report
            for (var h in hourlyUpdates) {
              report.hourlyData[h.hour] = h;
            }
            report.totalInput = totalInput;
            report.totalBalance = totalBalance;

            widget.onAdd(report);
            Navigator.pop(context);
          },
          child: const Text('Save Report'),
        ),
      ],
    );
  }
}

// ==================== HOURLY UPDATE EDITOR ====================

class HourlyUpdateEditorDialog extends StatefulWidget {
  final HourlyUpdate hourlyUpdate;
  final String department;
  final Function onSave;

  const HourlyUpdateEditorDialog({
    super.key,
    required this.hourlyUpdate,
    required this.department,
    required this.onSave,
  });

  @override
  State<HourlyUpdateEditorDialog> createState() =>
      _HourlyUpdateEditorDialogState();
}

class _HourlyUpdateEditorDialogState extends State<HourlyUpdateEditorDialog> {
  late List<LineData> lines;

  @override
  void initState() {
    super.initState();
    lines = List.from(widget.hourlyUpdate.lines);
  }

  @override
  Widget build(BuildContext context) {
return Dialog(
  insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hour ${widget.hourlyUpdate.hour} - ${widget.department}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Achievement'),
                Text(
                  '${widget.hourlyUpdate.getTotalInput()} Pcs',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Line Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: lines
                    .asMap()
                    .entries
                    .map((e) => _buildLineEditorCard(e.key, e.value))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.hourlyUpdate.lines = lines;
                  widget.onSave();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

  }

  Widget _buildLineEditorCard(int idx, LineData line) {
    final targetController = TextEditingController(text: line.target.toString());
    final achieveController =
        TextEditingController(text: line.achieve.toString());
    final balanceController = TextEditingController(text: line.balance.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line-${line.lineNumber} Unit-${line.unitNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => lines.removeAt(idx));
                  },
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target',
                prefixIcon: Icon(Icons.flag),
                isDense: true,
              ),
              onChanged: (val) =>
                  line.target = int.tryParse(val) ?? line.target,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: achieveController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Achieve',
                prefixIcon: Icon(Icons.check_circle),
                isDense: true,
              ),
              onChanged: (val) =>
                  line.achieve = int.tryParse(val) ?? line.achieve,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Balance',
                prefixIcon: Icon(Icons.assessment),
                isDense: true,
              ),
              onChanged: (val) =>
                  line.balance = int.tryParse(val) ?? line.balance,
            ),
          ],
        ),
      ),
    );
  }

  void _addNewLine() {
    setState(() {
      int maxLineNumber =
          lines.isNotEmpty ? lines.map((l) => l.lineNumber).reduce((a, b) => a > b ? a : b) : 0;
      lines.add(LineData(
        lineNumber: maxLineNumber + 1,
        unitNumber: 1,
        target: 100,
      ));
    });
  }
}

// Helper extension
extension GroupBy<K, V> on List<V> {
  Map<K, List<V>> groupBy<K>(K Function(V) keyFn) {
    final map = <K, List<V>>{};
    for (final item in this) {
      final key = keyFn(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}
