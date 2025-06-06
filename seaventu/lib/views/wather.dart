import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'config.dart';

class WeatherForecast {
  final DateTime date;
  final String time;
  final double temperature;
  final String description;
  final String icon;
  final double windSpeed;
  final int humidity;

  WeatherForecast({
    required this.date,
    required this.time,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.humidity,
  });
}

class WeatherPage extends StatefulWidget {
  final String? initialCity;

  const WeatherPage({super.key, this.initialCity});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with TickerProviderStateMixin {
  String _cityName = 'Loading...';
  String _temperature = '';
  String _description = '';
  String _humidity = '';
  String _realFeel = '';
  String _wind = '';
  String _windGusts = '';
  String _airQuality = '';
  String _errorMessage = '';
  bool _isLoading = false;
  bool _usingCurrentLocation = false;
  late AnimationController _animationController;
  List<WeatherForecast> _forecasts = [];
  bool _isForecastLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _cityName = widget.initialCity ?? 'Galle';
    _fetchWeatherUsingLocation();
    _getWeatherForecast();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherUsingLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final position = await _getCurrentLocation();
      if (position != null) {
        final city = await _getCityFromCoordinates(position);
        setState(() {
          _usingCurrentLocation = true;
          if (city != null) _cityName = city;
        });
        await _getWeatherData();
        await _getWeatherForecast();
      } else {
        await _getWeatherData();
        await _getWeatherForecast();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Location error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getCityFromCoordinates(Position position) async {
    try {
      const apiKey = Config.weatherApiKey;
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['name'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _getWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const apiKey = Config.weatherApiKey;
      final url =
          'https://api.openweathermap.org/data/2.5/weather?q=$_cityName&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _temperature = data['main']['temp'].toStringAsFixed(1);
          _description = data['weather'][0]['description'];
          _humidity = data['main']['humidity'].toString();
          _realFeel = data['main']['feels_like'].toStringAsFixed(1);
          _wind = '${(data['wind']['speed'] * 3.6).toStringAsFixed(1)} km/h';
          _windGusts = data['wind']['gust'] != null
              ? '${(data['wind']['gust'] * 3.6).toStringAsFixed(1)} km/h'
              : 'N/A';
          _airQuality = 'Fair';
          _errorMessage = '';
        });
      } else {
        setState(() => _errorMessage = 'Failed to load weather data');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getWeatherForecast() async {
    setState(() => _isForecastLoading = true);

    try {
      final url =
          'https://api.openweathermap.org/data/2.5/forecast?q=$_cityName&appid=${Config.weatherApiKey}&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<WeatherForecast> forecasts = [];

        // Group forecasts by day
        final dailyForecasts = <String, List<dynamic>>{};
        for (var item in data['list']) {
          final date = DateFormat('yyyy-MM-dd')
              .format(DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000));
          if (!dailyForecasts.containsKey(date)) {
            dailyForecasts[date] = [];
          }
          dailyForecasts[date]!.add(item);
        }

        // Get one forecast per day (around noon)
        for (var date in dailyForecasts.keys) {
          final dayForecasts = dailyForecasts[date]!;
          // Find forecast closest to 12:00 PM
          var noonForecast = dayForecasts.firstWhere(
            (f) =>
                DateTime.fromMillisecondsSinceEpoch(f['dt'] * 1000).hour >= 12,
            orElse: () => dayForecasts.last,
          );

          final dateTime =
              DateTime.fromMillisecondsSinceEpoch(noonForecast['dt'] * 1000);
          forecasts.add(WeatherForecast(
            date: dateTime,
            time: DateFormat('h a').format(dateTime),
            temperature: noonForecast['main']['temp'].toDouble(),
            description: noonForecast['weather'][0]['description'],
            icon: noonForecast['weather'][0]['icon'],
            windSpeed: noonForecast['wind']['speed'].toDouble(),
            humidity: noonForecast['main']['humidity'].toInt(),
          ));
        }

        setState(() => _forecasts = forecasts.take(5).toList());
      }
    } catch (e) {
      debugPrint('Forecast error: $e');
    } finally {
      setState(() => _isForecastLoading = false);
    }
  }

  String _getLottieAnimation(String condition) {
    if (condition.contains('clear')) return 'assets/animation/sunny.json';
    if (condition.contains('rain')) return 'assets/animation/rainy.json';
    if (condition.contains('cloud')) return 'assets/animation/cloudy.json';
    if (condition.contains('thunder') || condition.contains('storm')) {
      return 'assets/animation/thunderstorm.json';
    }
    return 'assets/animations/partly-cloudy.json';
  }

  String _getWeatherIcon(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  Future<void> _handleRefresh() async {
    if (_usingCurrentLocation) {
      await _fetchWeatherUsingLocation();
    } else {
      await _getWeatherData();
    }
    await _getWeatherForecast();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Colors.deepPurple.shade900, Colors.black87]
                : [Colors.blue.shade300, Colors.lightBlue.shade100],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: isDarkMode ? Colors.white : Colors.black,
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  iconTheme: const IconThemeData(color: Colors.white),
                  expandedHeight: isDesktop ? 90 : 100,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Weather',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isDesktop ? 28 : 24,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.3),
                          )
                        ],
                      ),
                    ),
                    centerTitle: isDesktop,
                    background: Container(color: Colors.transparent),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      
                      icon: Icon(
                        
                        Icons.location_searching,
                        size: isDesktop ? 28 : 24,
                        color: Colors.white
                      ),
                      onPressed: _fetchWeatherUsingLocation,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: isDesktop ? 28 : 24,
                        color: Colors.white
                      ),
                      onPressed: _isLoading ? null : _handleRefresh,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 800 : double.infinity,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.3),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.1),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding:
                                    EdgeInsets.all(isDesktop ? 32.0 : 20.0),
                                child: Column(
                                  children: [
                                    Text(
                                      _cityName,
                                      style: TextStyle(
                                        fontSize: isDesktop ? 32 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: isDesktop ? 20 : 10),
                                    SizedBox(
                                      height: isDesktop ? 200 : 150,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (_description.isNotEmpty)
                                            Lottie.asset(
                                              _getLottieAnimation(_description),
                                              width: isDesktop ? 160 : 120,
                                              height: isDesktop ? 160 : 120,
                                              controller: _animationController,
                                              fit: BoxFit.cover,
                                            ),
                                          SizedBox(width: isDesktop ? 40 : 20),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 500),
                                            child: Text(
                                              _temperature.isNotEmpty
                                                  ? '$_temperature°C'
                                                  : '--°C',
                                              key: ValueKey(_temperature),
                                              style: TextStyle(
                                                fontSize: isDesktop ? 64 : 48,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _description.isNotEmpty
                                          ? _description.toUpperCase()
                                          : 'LOADING...',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 20 : 16,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: isDesktop ? 30 : 20),
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: isDesktop ? 4 : 2,
                                      childAspectRatio: isDesktop ? 2.5 : 3,
                                      children: [
                                        _buildDetailItem(
                                          icon:
                                              FontAwesomeIcons.temperatureHalf,
                                          value: _realFeel.isNotEmpty
                                              ? '$_realFeel°C'
                                              : '--°C',
                                          label: 'Feels Like',
                                          color: Colors.orange,
                                          isDesktop: isDesktop,
                                        ),
                                        _buildDetailItem(
                                          icon: FontAwesomeIcons.droplet,
                                          value: _humidity.isNotEmpty
                                              ? '$_humidity%'
                                              : '--%',
                                          label: 'Humidity',
                                          color: Colors.blue,
                                          isDesktop: isDesktop,
                                        ),
                                        _buildDetailItem(
                                          icon: FontAwesomeIcons.wind,
                                          value: _wind.isNotEmpty
                                              ? _wind
                                              : '-- km/h',
                                          label: 'Wind',
                                          color: Colors.green,
                                          isDesktop: isDesktop,
                                        ),
                                        _buildDetailItem(
                                          icon: FontAwesomeIcons.wind,
                                          value: _windGusts.isNotEmpty
                                              ? _windGusts
                                              : '-- km/h',
                                          label: 'Gusts',
                                          color: Colors.red,
                                          isDesktop: isDesktop,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 800 : double.infinity,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                '5-Day Forecast',
                                style: TextStyle(
                                  fontSize: isDesktop ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _isForecastLoading
                                ? const Center(child: CircularProgressIndicator())
                                : SizedBox(
                                    height: isDesktop ? 250 : 210,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _forecasts.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                        final forecast = _forecasts[index];
                                        return GestureDetector(
                                          onTap: () {
                                            // Add tap functionality if needed
                                          },
                                          child: Container(
                                            width: isDesktop ? 160 : 140,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  isDarkMode
                                                      ? Colors.blueGrey
                                                          .withOpacity(0.3)
                                                      : Colors.lightBlue
                                                          .withOpacity(0.2),
                                                  isDarkMode
                                                      ? Colors.black
                                                          .withOpacity(0.2)
                                                      : Colors.white
                                                          .withOpacity(0.2),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                )
                                              ],
                                              border: Border.all(
                                                color: isDarkMode
                                                    ? Colors.white
                                                        .withOpacity(0.1)
                                                    : Colors.black
                                                        .withOpacity(0.1),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  DateFormat('EEE')
                                                      .format(forecast.date),
                                                  style: TextStyle(
                                                    fontSize:
                                                        isDesktop ? 18 : 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Lottie.asset(
                                                  _getLottieAnimation(
                                                      forecast.description),
                                                  width: isDesktop ? 70 : 60,
                                                  height: isDesktop ? 70 : 60,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${forecast.temperature.toStringAsFixed(1)}°C',
                                                  style: TextStyle(
                                                    fontSize:
                                                        isDesktop ? 20 : 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  forecast.description,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize:
                                                        isDesktop ? 14 : 12,
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      FontAwesomeIcons.wind,
                                                      size: isDesktop ? 16 : 14,
                                                      color: Colors.green,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${(forecast.windSpeed * 3.6).toStringAsFixed(1)} km/h',
                                                      style: TextStyle(
                                                        fontSize:
                                                            isDesktop ? 14 : 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 800 : double.infinity,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                        child: Text(
                          _errorMessage.isNotEmpty
                              ? _errorMessage
                              : "Southern Provincial Irrigation Department",
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            color: _errorMessage.isNotEmpty
                                ? Colors.red
                                : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDesktop,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16.0 : 8.0,
        vertical: isDesktop ? 8.0 : 0,
      ),
      child: Row(
        children: [
          Icon(icon, size: isDesktop ? 28 : 24, color: color),
          SizedBox(width: isDesktop ? 12 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
