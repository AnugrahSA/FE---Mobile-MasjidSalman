import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TestFitur extends StatefulWidget {
  const TestFitur({super.key});

  @override
  State<TestFitur> createState() => _TestFiturState();
}

class _TestFiturState extends State<TestFitur> {
  String? dropdownValue1;
  String? dropdownValue2;
  String? dropdownValue3;
  String? dropdownValue4;
  String jumlahRealisasiText = '';
  String sumberDanaText = '';
  String nilaiSatuanText = '';
  int totalNilaiSatuan = 0;
  int totalDanaDigunakan = 0;
  int totalSaldo = 0;
  List<String> namaProgramKegiatanList = [];
  List<Map<String, dynamic>> programOptions = [];
  List<Map<String, dynamic>> bidangOptions = [];
  List<String> filteredProgramOptions = [];
  final List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];
  final List<String> years =
      List.generate(4, (index) => (2024 - index).toString());
  bool _showCard = false;
  int selectedIndex = -1;
  List<String> fetchedDataList = [];
  List<String> kategoriList = [];
  List<String> rutinitasList = [];
  List<String> rencanaList = [];
  List<String> realisasiList = [];
  List<String> indikatorList = [];
  List<String> targetList = [];
  List<String> capaianList = [];
  List<Map<String, dynamic>> pelaksanaans = [];
  int currentPage = 0;
  final int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    fetchProgramOptions();
    fetchBidangOptions();
  }

  Future<void> fetchProgramOptions() async {
    final response = await http.get(
      Uri.parse('https://salimapi.admfirst.my.id/api/mobile/program'),
      headers: {
        'User-Agent': 'SalmanITB/1.0.0',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        programOptions = data
            .map((item) => {
                  'id_bidang': item['id_bidang'],
                  'id': item['id'],
                  'nama': item['nama']
                })
            .toList();
        filterProgramOptions();
      });
    } else {
      print('Failed to load program options');
    }
  }

  Future<void> fetchBidangOptions() async {
    final response = await http.get(
      Uri.parse('https://salimapi.admfirst.my.id/api/mobile/bidang'),
      headers: {
        'User-Agent': 'SalmanITB/1.0.0',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        bidangOptions = data
            .map((item) => {'id': item['id'], 'nama': item['nama']})
            .toList();
      });
    } else {
      print('Failed to load bidang options');
    }
  }

  Future<void> fetchData() async {
    if (dropdownValue1 != null &&
        dropdownValue2 != null &&
        dropdownValue3 != null) {
      final idProgram = programOptions
          .firstWhere((program) => program['nama'] == dropdownValue1)['id'];
      final month = months.indexOf(dropdownValue2!) + 1;
      final year = dropdownValue3;

      final response = await http.get(
        Uri.parse(
            'https://salimapi.admfirst.my.id/api/mobile/laporan?id_program=$idProgram&month=$month&year=$year'),
        headers: {
          'User-Agent': 'SalmanITB/1.0.0 ',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alokasiDanas = data['alokasi_danas'] as List<dynamic>? ?? [];
        final penerimaManfaats =
            data['penerima_manfaats'] as List<dynamic>? ?? [];
        final kpiBulanans = data['k_p_i_bulanans'] as List<dynamic>? ?? [];
        final pelaksanaansData = data['pelaksanaans'] as List<dynamic>? ?? [];

        if (alokasiDanas.isNotEmpty) {
          setState(() {
            totalNilaiSatuan = alokasiDanas.fold<int>(0, (sum, item) {
              return sum +
                  ((item['item_kegiatan_r_k_a']?['nilai_satuan'] ?? 0) as num)
                      .toInt();
            });
            totalDanaDigunakan = alokasiDanas.fold<int>(0, (sum, item) {
              return sum + ((item['jumlah_realisasi'] ?? 0) as num).toInt();
            });
            totalSaldo = totalNilaiSatuan - totalDanaDigunakan;

            fetchedDataList = alokasiDanas
                .map((item) =>
                    item['item_kegiatan_r_k_a']?['uraian'].toString() ?? 'N/A')
                .toList();

            kategoriList = penerimaManfaats
                .map((item) => item['kategori'].toString() ?? 'N/A')
                .toList();

            rutinitasList = penerimaManfaats
                .map((item) => item['tipe_rutinitas'].toString() ?? 'N/A')
                .toList();

            rencanaList = penerimaManfaats
                .map((item) => item['rencana'].toString() ?? 'N/A')
                .toList();

            realisasiList = penerimaManfaats
                .map((item) => item['realisasi'].toString() ?? 'N/A')
                .toList();

            indikatorList = kpiBulanans
                .map((kpiBulanan) =>
                    kpiBulanan['kpi']['indikator'].toString() ?? 'N/A')
                .toList();

            targetList = kpiBulanans
                .map((kpiBulanan) =>
                    kpiBulanan['kpi']['target'].toString() ?? 'N/A')
                .toList();

            capaianList = kpiBulanans
                .map((kpiBulanan) => kpiBulanan['capaian'].toString() ?? 'N/A')
                .toList();

            pelaksanaans = pelaksanaansData
                .map((item) => item as Map<String, dynamic>)
                .toList();

            final firstAlokasiDana = alokasiDanas[0];
            final jumlahRealisasi =
                firstAlokasiDana['jumlah_realisasi'].toString();
            final sumberDana = firstAlokasiDana['item_kegiatan_r_k_a']
                        ?['sumber_dana']
                    .toString() ??
                'N/A';
            final nilaiSatuan = firstAlokasiDana['item_kegiatan_r_k_a']
                        ?['nilai_satuan']
                    .toString() ??
                'N/A';

            jumlahRealisasiText = jumlahRealisasi;
            sumberDanaText = sumberDana;
            nilaiSatuanText = nilaiSatuan;

            namaProgramKegiatanList = pelaksanaans.isNotEmpty
                ? pelaksanaans
                    .map((pelaksanaan) =>
                        pelaksanaan['program_kegiatan']['nama'].toString())
                    .toSet()
                    .toList()
                : ['tidak ada data'];
          });
        } else {
          setState(() {
            fetchedDataList = [];
            kategoriList = [];
            rutinitasList = [];
            rencanaList = [];
            realisasiList = [];
            jumlahRealisasiText = '';
            sumberDanaText = '';
            nilaiSatuanText = '';
            indikatorList = [];
            targetList = [];
            capaianList = [];
            pelaksanaans = [];
            namaProgramKegiatanList = ['tidak ada data'];
          });
        }
      } else {
        print('Failed to fetch data');
      }
    }
  }

  void filterProgramOptions() {
    if (dropdownValue4 != null) {
      final selectedBidang = bidangOptions
          .firstWhere((bidang) => bidang['nama'] == dropdownValue4);
      setState(() {
        filteredProgramOptions = programOptions
            .where((program) => program['id_bidang'] == selectedBidang['id'])
            .map((program) => program['nama'].toString())
            .toList();
        if (filteredProgramOptions.isEmpty) {
          filteredProgramOptions = ['tidak ada data'];
        }
      });
    } else {
      setState(() {
        filteredProgramOptions = ['tidak ada data'];
      });
    }
  }

  void onDropdownChanged() {
    if (dropdownValue1 != null &&
        dropdownValue2 != null &&
        dropdownValue3 != null) {
      fetchData();
    }
  }

  String formatCurrency(int amount) {
    final NumberFormat currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
    return currencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Align(
                  alignment: AlignmentDirectional(0, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 1),
                        child: Text(
                          'SI',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional(0, 0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
                          child: Text(
                            'Salman ITB',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF908F8F),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(0, 0),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 32, 0, 32),
                    child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: AlignmentDirectional(-1, 0),
                              child: Text(
                                'Selamat datang',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(-1, 0),
                              child: Text(
                                'Dapatkan kemudahan akses informasi di mana pun',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF757171),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdown(
                        value: dropdownValue4,
                        hint: 'Bidang Pengkajian dan Penerbitan',
                        items: bidangOptions
                            .map((bidang) => bidang['nama'].toString())
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue4 = newValue;
                            dropdownValue1 = null;
                            filterProgramOptions();
                            onDropdownChanged();
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildDropdown(
                        value: dropdownValue1,
                        hint: 'Program Kepustakaan',
                        items: filteredProgramOptions,
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue1 = newValue;
                            onDropdownChanged();
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        value: dropdownValue2,
                        hint: 'Januari',
                        items: months,
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue2 = newValue;
                            onDropdownChanged();
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
                        value: dropdownValue3,
                        hint: '2024',
                        items: years,
                        onChanged: (String? newValue) {
                          setState(() {
                            dropdownValue3 = newValue;
                            onDropdownChanged();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 14,
                ),
                Align(
                  alignment: AlignmentDirectional(-1, 0),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 14),
                    child: Text(
                      'Laporan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional(-1, 0),
                  child: Container(
                    constraints: BoxConstraints(minHeight: 85, minWidth: 324),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Align(
                      alignment: AlignmentDirectional(-1, 0),
                      child: Card(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        color: Color(0xFF967C55),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Align(
                          alignment: AlignmentDirectional(0, 0),
                          child: Padding(
                            padding:
                                EdgeInsetsDirectional.fromSTEB(21, 25, 21, 25),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Align(
                                        alignment: AlignmentDirectional(-1, 0),
                                        child: Text(
                                          'Dana yang direncanakan',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            21, 0, 9, 0),
                                        child: Text(
                                          ':',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0, 0, 16, 0),
                                        child: Text(
                                          'RP',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          formatCurrency(totalNilaiSatuan),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Align(
                                        alignment: AlignmentDirectional(-1, 0),
                                        child: Text(
                                          'Dana yang digunakan',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            37, 0, 9, 0),
                                        child: Text(
                                          ':',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0, 0, 16, 0),
                                        child: Text(
                                          'RP',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          formatCurrency(totalDanaDigunakan),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Align(
                                        alignment: AlignmentDirectional(-1, 0),
                                        child: Text(
                                          'Saldo',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            120, 0, 9, 0),
                                        child: Text(
                                          ':',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0, 0, 16, 0),
                                        child: Text(
                                          'RP',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          formatCurrency(totalSaldo),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 14,
                ),
                Align(
                  alignment: AlignmentDirectional(-1, 0),
                  child: Text(
                    'Kategori Pengeluaran',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.black,
                      fontSize: 12,
                      letterSpacing: 0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 14,
                ),
                if (fetchedDataList.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: fetchedDataList.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showCard = selectedIndex != index;
                                selectedIndex = _showCard ? index : -1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Color.fromARGB(255, 255, 255, 255),
                              minimumSize: Size(double.infinity, 40),
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fetchedDataList[index],
                                  style: TextStyle(
                                    fontFamily: 'Readex Pro',
                                    color: Colors.black,
                                    fontSize: 14,
                                    letterSpacing: 0,
                                  ),
                                ),
                                FaIcon(
                                  FontAwesomeIcons.caretRight,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                          if (_showCard && selectedIndex == index)
                            Container(
                              constraints:
                                  BoxConstraints(minHeight: 85, minWidth: 324),
                              margin: EdgeInsets.only(top: 3),
                              child: Card(
                                color: Color(0xFF967C55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Container(
                                  constraints: BoxConstraints(
                                      minHeight: 85, minWidth: 324),
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 0),
                                              child: Text(
                                                'Jumlah Realisasi',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 0),
                                              child: Text(
                                                ':',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 0),
                                              child: Text(
                                                'Rp',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 0),
                                              child: Text(
                                                jumlahRealisasiText,
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 0),
                                              child: Text(
                                                'Jumlah Rencana',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 0),
                                              child: Text(
                                                ':',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 0),
                                              child: Text(
                                                'Rp',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 0),
                                              child: Text(
                                                nilaiSatuanText,
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 14),
                                              child: Text(
                                                'Sumber Dana',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(41, 14, 0, 14),
                                              child: Text(
                                                ':',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(21, 14, 0, 14),
                                              child: Text(
                                                '',
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1, 0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(42, 14, 0, 14),
                                              child: Text(
                                                sumberDanaText,
                                                style: TextStyle(
                                                  fontFamily: 'Readex Pro',
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
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
                            ),
                        ],
                      );
                    },
                  ),
                if (fetchedDataList.length > itemsPerPage)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 0
                            ? () {
                                setState(() {
                                  currentPage--;
                                });
                              }
                            : null,
                        child: Text('Previous'),
                      ),
                      ElevatedButton(
                        onPressed: (currentPage + 1) * itemsPerPage <
                                fetchedDataList.length
                            ? () {
                                setState(() {
                                  currentPage++;
                                });
                              }
                            : null,
                        child: Text('Next'),
                      ),
                    ],
                  ),
                SizedBox(
                  height: 6,
                ),
                Align(
                  alignment: AlignmentDirectional(-1, 0),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 14, 0, 14),
                    child: Text(
                      'Penerima Manfaat',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Table(
                  border: TableBorder.all(color: Colors.white),
                  children: [
                    TableRow(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Color(0xFF967c55),
                          child: Center(
                            child: Text(
                              'Kategori',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Color(0xFF967c55),
                          child: Center(
                            child: Text(
                              'Rutinitas',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Color(0xFF967c55),
                          child: Center(
                            child: Text(
                              'Rencana',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Color(0xFF967c55),
                          child: Center(
                            child: Text(
                              'Realisasi',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (kategoriList.isEmpty)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text('tidak ada data')),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text('tidak ada data')),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text('tidak ada data')),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text('tidak ada data')),
                          ),
                        ],
                      )
                    else
                      for (int i = currentPage * itemsPerPage;
                          i < kategoriList.length &&
                              i < (currentPage + 1) * itemsPerPage;
                          i++)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                  child: Text(kategoriList.isNotEmpty
                                      ? kategoriList[i]
                                      : '')),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                  child: Text(rutinitasList.isNotEmpty
                                      ? rutinitasList[i]
                                      : '')),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                  child: Text(rencanaList.isNotEmpty
                                      ? rencanaList[i]
                                      : '')),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                  child: Text(realisasiList.isNotEmpty
                                      ? realisasiList[i]
                                      : '')),
                            ),
                          ],
                        ),
                  ],
                ),
                SizedBox(
                  height: 14,
                ),
                Align(
                  alignment: AlignmentDirectional(-1, 0),
                  child: Text(
                    'Deskripsi Pelaksanaan Kegiatan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.black,
                      fontSize: 12,
                      letterSpacing: 0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Column(
                  children: namaProgramKegiatanList.map((namaProgram) {
                    final filteredPelaksanaans = pelaksanaans
                        .where((pelaksanaan) =>
                            pelaksanaan['program_kegiatan']['nama'] ==
                            namaProgram)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional(-1, 0),
                          child: Text(
                            namaProgram,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.black,
                              fontSize: 12,
                              letterSpacing: 0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (filteredPelaksanaans.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: filteredPelaksanaans.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _showCard = selectedIndex != index;
                                        selectedIndex = _showCard ? index : -1;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      minimumSize: Size(double.infinity, 40),
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 24),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            filteredPelaksanaans[index]
                                                    ['penjelasan']
                                                .toString(),
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontFamily: 'Readex Pro',
                                              fontSize: 14,
                                              letterSpacing: 0,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        FaIcon(
                                          FontAwesomeIcons.caretRight,
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_showCard && selectedIndex == index)
                                    Container(
                                      constraints: BoxConstraints(
                                          minHeight: 85, minWidth: 324),
                                      margin: EdgeInsets.only(top: 3),
                                      child: Card(
                                        color: Color(0xFF967C55),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Container(
                                          constraints: BoxConstraints(
                                              minHeight: 85, minWidth: 324),
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            -1, 0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  21, 14, 0, 0),
                                                      child: Text(
                                                        'Waktu',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            -1, 0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  65, 14, 0, 0),
                                                      child: Text(
                                                        ':',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1, 0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(21,
                                                                    14, 0, 0),
                                                        child: Text(
                                                          filteredPelaksanaans[
                                                                      index]
                                                                  ['waktu']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Readex Pro',
                                                            letterSpacing: 0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Flexible(
                                                    child: Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1, 0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(21,
                                                                    14, 0, 0),
                                                        child: Text(
                                                          'Tempat',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Readex Pro',
                                                            letterSpacing: 0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            -1, 0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 14, 0, 0),
                                                      child: Text(
                                                        ':',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            -1, 0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  22, 14, 0, 0),
                                                      child: Text(
                                                        filteredPelaksanaans[
                                                                index]['tempat']
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            -1, 0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(21, 14,
                                                                  0, 14),
                                                      child: Text(
                                                        'Penyaluran',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            -1, 0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(34, 14,
                                                                  0, 14),
                                                      child: Text(
                                                        ':',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1, 0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(24,
                                                                    14, 0, 14),
                                                        child: Text(
                                                          filteredPelaksanaans[
                                                                      index]
                                                                  ['penyaluran']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Readex Pro',
                                                            letterSpacing: 0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    );
                  }).toList(),
                ),
                SizedBox(
                  height: 14,
                ),
                Align(
                  alignment: AlignmentDirectional(-1, 0),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 14, 0, 14),
                    child: Text(
                      'Deskripsi Pelaksanaan Kegiatan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 14,
                ),
                Table(
                  border: TableBorder.all(color: Colors.white),
                  children: [
                    TableRow(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          color: Color(0xFF967c55),
                          child: Center(
                            child: Text(
                              'Indikator',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3.7),
                          color: Color(0xFF967c55),
                          child: Center(
                            child: Text(
                              'Target Indikator',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          color: Color(0xFF967c55),
                          child: Center(
                            child: Text(
                              'Capaian',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (indikatorList.isEmpty)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text('tidak ada data')),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text('tidak ada data')),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text('tidak ada data')),
                          ),
                        ],
                      )
                    else
                      for (int i = 0; i < indikatorList.length; i++)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(child: Text(indikatorList[i])),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(child: Text(targetList[i])),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(child: Text(capaianList[i])),
                            ),
                          ],
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildDropdown({
  required String? value,
  required String hint,
  required List<String> items,
  required void Function(String?) onChanged,
}) {
  return Container(
    height: 35,
    padding: EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(4),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: TextStyle(fontSize: 12)),
        isExpanded: true,
        icon: FaIcon(
          FontAwesomeIcons.caretDown,
          color: Colors.grey,
          size: 16.0,
        ),
        onChanged: onChanged,
        items: items.asMap().entries.map<DropdownMenuItem<String>>((entry) {
          int index = entry.key;
          String item = entry.value;
          Color color = index % 2 == 0 ? Colors.white : Colors.grey[300]!;
          return DropdownMenuItem<String>(
            value: item,
            child: Container(
              color: color,
              child: Text(
                item,
                style: TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}
