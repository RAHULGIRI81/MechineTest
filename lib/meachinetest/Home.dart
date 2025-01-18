import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mechinetest1/meachinetest/login.dart';

class Home extends StatefulWidget {
  final String userId;
  const Home({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String searchQuery = '';
  String expertiseFilter = 'All';
  final List<String> expertiseOptions = ['All', 'Flutter', 'MERN', 'UI/UX', 'Digital Marketing'];
  String userName = 'User';

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  void fetchUserName() async {
    final userDoc = await _firestore.collection('users').doc(widget.userId).get();
    if (userDoc.exists) {
      setState(() {
        userName = userDoc['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text('Welcome, $userName', style: GoogleFonts.poppins(fontSize: 24,fontWeight: FontWeight.bold)),
            Icon(Icons.waving_hand,color: Colors.yellow.shade900,)
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: expertiseOptions.map((category) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        expertiseFilter = category;
                      });
                    },
                    child: Chip(
                      label: Text(category),
                      backgroundColor: expertiseFilter == category ? Colors.blue.shade400 : Colors.grey[300],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data!.docs;
                var filteredStudents = students.where((student) {
                  final name = student['name'].toLowerCase();
                  final expertise = student['expertise'].toLowerCase();
                  return name.contains(searchQuery) && (expertiseFilter == 'All' || expertise == expertiseFilter.toLowerCase());
                }).toList();

                filteredStudents.sort((a, b) {
                  return a['name'].compareTo(b['name']);
                });

                return ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return Card(
                      child: ListTile(
                        title: Text(student['name'] ?? 'data null'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expertise: ${student['expertise'] ?? 'data null'}'),
                            Text('Email: ${student['email'] ?? 'data null'}'),
                            Text('Phone: ${student['phone'] ?? 'data null'}'),
                            Text('Place: ${student['place'] ?? 'data null'}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
