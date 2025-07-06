import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../providers/data_provider.dart';
import '../models/secure_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

// Data classes for charts
class CategoryData {
  final String category;
  final int count;
  final Color color;

  CategoryData(this.category, this.count, this.color);
}

class ActivityData {
  final String date;
  final int count;

  ActivityData(this.date, this.count);
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartAnimationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _chartAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Consumer<DataProvider>(
                    builder: (context, dataProvider, child) {
                      return _buildStatisticsContent(dataProvider);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              'Statistics',
                              textStyle: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              speed: const Duration(milliseconds: 100),
                            ),
                          ],
                          totalRepeatCount: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Digital Vault Analytics',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsContent(DataProvider dataProvider) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(dataProvider),
                const SizedBox(height: 24),
                _buildCategoryDistributionChart(dataProvider),
                const SizedBox(height: 24),
                _buildActivityChart(dataProvider),
                const SizedBox(height: 24),
                _buildSecurityMetrics(dataProvider),
                const SizedBox(height: 24),
                _buildRecentActivity(dataProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCards(DataProvider dataProvider) {
    final totalEntries = dataProvider.totalEntries;
    final categoriesUsed = _getCategoriesUsed(dataProvider);
    final securityScore = _calculateSecurityScore(dataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGray,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildAnimatedStatCard(
              'Total Entries',
              totalEntries.toString(),
              Icons.shield_rounded,
              AppTheme.primaryBlue,
              0,
            ),
            _buildAnimatedStatCard(
              'Categories Used',
              categoriesUsed.toString(),
              Icons.category_rounded,
              AppTheme.primaryPurple,
              200,
            ),
            _buildAnimatedStatCard(
              'Security Score',
              '${securityScore.toInt()}%',
              Icons.security_rounded,
              AppTheme.successGreen,
              400,
            ),
            _buildAnimatedStatCard(
              'Encrypted Items',
              totalEntries.toString(),
              Icons.lock_rounded,
              AppTheme.warningOrange,
              600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedStatCard(String title, String value, IconData icon, Color color, int delay) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: 0.8), color],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        value,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGray,
                        ),
                        speed: const Duration(milliseconds: 50),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryDistributionChart(DataProvider dataProvider) {
    final categoryData = _getCategoryData(dataProvider);

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.pie_chart_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Category Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: categoryData.isEmpty
                        ? _buildEmptyChart()
                        : SfCircularChart(
                            legend: const Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                              textStyle: TextStyle(fontSize: 10),
                            ),
                            series: <CircularSeries>[
                              DoughnutSeries<CategoryData, String>(
                                dataSource: categoryData,
                                xValueMapper: (CategoryData data, _) => data.category,
                                yValueMapper: (CategoryData data, _) => data.count,
                                pointColorMapper: (CategoryData data, _) => data.color,
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.outside,
                                  textStyle: TextStyle(fontSize: 10),
                                ),
                                innerRadius: '60%',
                                animationDuration: 2000,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityChart(DataProvider dataProvider) {
    final activityData = _getActivityData(dataProvider);

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Activity Trend',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: activityData.isEmpty
                        ? _buildEmptyChart()
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return const FlLine(
                                    color: AppTheme.lightGray,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      if (value.toInt() < activityData.length) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            activityData[value.toInt()].date,
                                            style: const TextStyle(
                                              color: AppTheme.mediumGray,
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: AppTheme.mediumGray,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                    reservedSize: 32,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: AppTheme.lightGray,
                                  width: 1,
                                ),
                              ),
                              minX: 0,
                              maxX: (activityData.length - 1).toDouble(),
                              minY: 0,
                              maxY: activityData.isEmpty ? 10 : activityData.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble() + 1,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: activityData.asMap().entries.map((entry) {
                                    return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
                                  }).toList(),
                                  isCurved: true,
                                  gradient: AppTheme.primaryGradient,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: AppTheme.primaryBlue,
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppTheme.primaryBlue.withValues(alpha: 0.3),
                                        AppTheme.primaryBlue.withValues(alpha: 0.1),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityMetrics(DataProvider dataProvider) {
    final securityScore = _calculateSecurityScore(dataProvider);

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Security Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSecurityScoreIndicator(securityScore),
                  const SizedBox(height: 20),
                  _buildSecurityRecommendations(dataProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityScoreIndicator(double score) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.lightGray,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      score >= 80 ? AppTheme.successGreen :
                      score >= 60 ? AppTheme.warningOrange : AppTheme.errorRed,
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          '${score.toInt()}%',
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                          speed: const Duration(milliseconds: 50),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),
                    const Text(
                      'Security Score',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityRecommendations(DataProvider dataProvider) {
    final recommendations = _getSecurityRecommendations(dataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        ...recommendations.map((recommendation) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRecentActivity(DataProvider dataProvider) {
    final recentEntries = dataProvider.entries.take(5).toList();

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (recentEntries.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No recent activity',
                          style: TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ...recentEntries.map((entry) => _buildActivityItem(entry)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(SecureEntry entry) {
    final color = Color(int.parse(entry.type.colorHex.substring(1), radix: 16) + 0xFF000000);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                entry.type.icon,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Updated ${_formatDate(entry.updatedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppTheme.mediumGray,
          ),
          SizedBox(height: 12),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  int _getCategoriesUsed(DataProvider dataProvider) {
    final usedTypes = <SecureEntryType>{};
    for (final entry in dataProvider.entries) {
      usedTypes.add(entry.type);
    }
    return usedTypes.length;
  }

  double _calculateSecurityScore(DataProvider dataProvider) {
    if (dataProvider.entries.isEmpty) return 0.0;

    double score = 0.0;
    final totalEntries = dataProvider.entries.length;

    // Base score for having entries
    score += 20.0;

    // Score for diversity of entry types
    final usedTypes = _getCategoriesUsed(dataProvider);
    score += (usedTypes / SecureEntryType.values.length) * 30.0;

    // Score for number of entries
    score += (totalEntries.clamp(0, 20) / 20.0) * 30.0;

    // Score for recent activity
    final recentEntries = dataProvider.entries.where((entry) {
      final now = DateTime.now();
      final entryDate = entry.updatedAt;
      return now.difference(entryDate).inDays <= 30;
    }).length;
    score += (recentEntries / totalEntries) * 20.0;

    return score.clamp(0.0, 100.0);
  }

  List<CategoryData> _getCategoryData(DataProvider dataProvider) {
    final categoryCount = <SecureEntryType, int>{};

    for (final entry in dataProvider.entries) {
      categoryCount[entry.type] = (categoryCount[entry.type] ?? 0) + 1;
    }

    return categoryCount.entries.map((entry) {
      final color = Color(int.parse(entry.key.colorHex.substring(1), radix: 16) + 0xFF000000);
      return CategoryData(entry.key.displayName, entry.value, color);
    }).toList();
  }

  List<ActivityData> _getActivityData(DataProvider dataProvider) {
    final activityMap = <String, int>{};
    final now = DateTime.now();

    // Generate last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.day}/${date.month}';
      activityMap[dateStr] = 0;
    }

    // Count entries updated in last 7 days
    for (final entry in dataProvider.entries) {
      final entryDate = entry.updatedAt;
      final daysDiff = now.difference(entryDate).inDays;

      if (daysDiff <= 6) {
        final dateStr = '${entryDate.day}/${entryDate.month}';
        if (activityMap.containsKey(dateStr)) {
          activityMap[dateStr] = activityMap[dateStr]! + 1;
        }
      }
    }

    return activityMap.entries.map((entry) => ActivityData(entry.key, entry.value)).toList();
  }

  List<String> _getSecurityRecommendations(DataProvider dataProvider) {
    final recommendations = <String>[];

    if (dataProvider.entries.length < 5) {
      recommendations.add('Add more entries to improve security coverage');
    }

    final usedTypes = _getCategoriesUsed(dataProvider);
    if (usedTypes < 3) {
      recommendations.add('Diversify your entry types for better organization');
    }

    final recentEntries = dataProvider.entries.where((entry) {
      return DateTime.now().difference(entry.updatedAt).inDays <= 30;
    }).length;

    if (recentEntries == 0 && dataProvider.entries.isNotEmpty) {
      recommendations.add('Update your entries regularly to maintain security');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Your vault is well-maintained!');
      recommendations.add('Consider adding backup entries for important accounts');
    }

    return recommendations;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
