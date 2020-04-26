import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:rateit/login.dart';
import 'package:rateit/user.dart';

import 'user.dart';

class FirestoreService{

  final String uid;
  FirestoreService({this.uid});

  final CollectionReference _usersCollectionReference = Firestore.instance.collection('users');

  Future registerUser(UserData user) async{
    try {
      await _usersCollectionReference.document(user.uid).setData(user.toJSON());
    } catch (e) {
      return e.message;
    }
  }

  Future<String> getUserRole(String uid) async {
    try{
      String userRole = '';
      await _usersCollectionReference.document(uid).get().then((value) => userRole = value.data['userRole']);
      return userRole;
    }catch(e){
      return e.toString();
    }
  }

  UserData _userDataFromSnapshot(DocumentSnapshot snapshot){
    return UserData(
      uid : snapshot.data['uid'],  
      firstName : snapshot.data['firstName'], 
      lastName : snapshot.data['lastName'], 
      gender : snapshot.data['gender'], 
      dateOfBirth : snapshot.data['dateOfBirth'], 
      email : snapshot.data['email'], 
      userRole : snapshot.data['userRole'],
    );
  }

  Stream<UserData> get userData {
    return _usersCollectionReference.document(uid).snapshots()
    .map(_userDataFromSnapshot);
  }

  Future<String> userRolePromise(String uid) async {
    try{
      String userrole = '';
      await Firestore.instance.collection("users").document(uid).get().then((value) => userrole = value.data['userRole']);
      print('called');
      return userrole;
    }catch(e){
      return "Error";
    }
  }

  Stream<String> get users  {
    return userRolePromise(uid).asStream();
  }

  Future normalSignOutPromise()  async{
    try{
      return await FirebaseAuth.instance.signOut();
    }
    catch(e){
      return null;
    }
    //return LoginScreen();
    // print("what");
    // BuildContext context;
    // Navigator.push(context,MaterialPageRoute(builder: (context)=>  LoginScreen() ),);
  }

}