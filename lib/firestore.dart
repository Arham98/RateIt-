import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:rateit/user.dart';
import 'Event.dart';
import 'user.dart';
import 'item.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FirestoreService{

  final String uid;
  FirestoreService({this.uid});

  final CollectionReference _usersCollectionReference = Firestore.instance.collection('users');
  final CollectionReference _vendorCollectionReference = Firestore.instance.collection('Vendor');
  final CollectionReference _itemCollectionReference = Firestore.instance.collection('item');
  final CollectionReference _reviewsCollectionReference = Firestore.instance.collection('review');
  final CollectionReference _ratedVendorCollectionReference = Firestore.instance.collection('ratedVendor');
  final CollectionReference _ratedItemCollectionReference = Firestore.instance.collection('ratedItems');
  final CollectionReference _eventCollectionReference = Firestore.instance.collection('Event');

  Future<String> registerUser(UserData user) async{
    try {
      await _usersCollectionReference.document(user.uid).setData(user.toJSON());
      return null;
    } catch (e) {
      return e.message;
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try{
      String userrole = '';
      await Firestore.instance.collection("users").document(uid).get().then((value) {
        userrole = value.data['userRole'];
        // trying shared preferences now 
        prefs.setString('uid', value.data['uid'] ?? '');
        prefs.setString('firstName', value.data['firstName'] ?? '');
        prefs.setString('lastName', value.data['lastName'] ?? '');
        prefs.setString('userRole', value.data['userRole'] ?? '');
        prefs.setString('gender', value.data['gender'] ?? '');
        prefs.setString('email', value.data['email'] ?? '');
        prefs.setString('profilePicture', value.data['profilePicture'] ?? '');
      });
      return userrole;
    }catch(e){
      return "Error";
    }
  }

  Stream<String> get users  {
    return userRolePromise(uid).asStream();
  }

  Future normalSignOutPromise()  async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try{
      prefs.remove('uid');
      prefs.remove('firstName');
      prefs.remove('lastName');
      prefs.remove('userRole');
      prefs.remove('gender');
      prefs.remove('profilePicture');
      if (prefs.getBool('rememberMe') == false){
        prefs.remove('email');
      }
      return await FirebaseAuth.instance.signOut().then((_) async {
        await Directory( (await getTemporaryDirectory()).path ).delete(recursive: true);
      });
    }
    catch(e){
      return null;
    }
  }

  // rate it backend 

  // get a list of vendors 
  List<Vendor> _vendorListFromSnapshot(QuerySnapshot snapshot){
    return  snapshot.documents.map((doc){
      return Vendor(
        aggregateRating: doc.data['aggregateRating'].toDouble() ?? 0.0,
        email: doc.data['email'] ?? '',
        eventId: doc.data['eventId'] ?? '',
        name: doc.data['name'] ?? '',
        qrCode: doc.data['qrCode'] ?? '',
        stallNo: doc.data['stallNo'] ?? -1,
        vendorId: doc.data['vendorId'] ?? '',
        logo: doc.data['logo'] ?? '',
      );
    }).toList();
  }

  // verify that invite code exists, if yes then send data 
  Future<QuerySnapshot> verifyInviteCode(String inviteCode) async {
    return await Firestore.instance.collection('Event').where('invitecode', isEqualTo: inviteCode).getDocuments();
  }

  // get vendors of that event 
  Stream<List<Vendor>> getVendorInfo(String eventID) {
    return _vendorCollectionReference.where('eventId', isEqualTo: eventID).orderBy('aggregateRating', descending: true).snapshots()
    .map(_vendorListFromSnapshot);
  }

  // for Vendor Details
  List<Item> _itemListFromSnapshot(QuerySnapshot snapshot){
    print(snapshot.documents.toString());
    return snapshot.documents.map((doc){
      return Item(
        itemId: doc.data['itemId'] ?? '',
        name: doc.data['name'] ?? '',
        vendorId: doc.data['vendorId'] ?? '',
        logo: doc.data['logo'] ?? '',
        aggregateRating: doc.data['aggregateRating'].toDouble() ?? 0.0,
      );
    }).toList();
  }

  Stream<List<Item>> getItemInfo(String vendorId){ //each vendor's top rated item query
    print('vendorId');
    return _itemCollectionReference.where('vendorId', isEqualTo: vendorId).snapshots()
    .map(_itemListFromSnapshot);
  }

  // For Rating
  Future<QuerySnapshot> getVendor(String vendorId){
    print(vendorId);
    return _vendorCollectionReference.where('vendorId', isEqualTo: vendorId).getDocuments();
  }

  Stream<List<Item>> getAllItemInfo(String vendorId){ //each vendor's all item query
    return _itemCollectionReference.where('vendorId', isEqualTo: vendorId).snapshots()
    .map(_itemListFromSnapshot);
  }

  //view my rating
  List<RatedVendor> _ratedVendorListFromSnapshot(QuerySnapshot snapshot){
    return snapshot.documents.map((doc){
      return RatedVendor(
        userId: doc.data['userId'] ?? '',
        vendorId: doc.data['vendorId'] ?? '',
        vendorName: doc.data['vendorName'] ?? '',
        vendorLogo: doc.data['vendorLogo'] ?? '',
        rating: doc.data['myVendorRating'].toDouble() ?? 0.0,
        reviewId: doc.data['vendorReviewId'] ?? '',
      );
    }).toList();
  }

  Stream<List<RatedVendor>> getMyRatedVendor(String uid){
    print(uid);
    return _ratedVendorCollectionReference.where('userId', isEqualTo: uid).snapshots()
    .map(_ratedVendorListFromSnapshot);
  }

  List<RatedItem> _ratedItemListFromSnapshot(QuerySnapshot snapshot){
    return snapshot.documents.map((doc){
      return RatedItem(
        userId: doc.data['userId'] ?? '',
        vendorId: doc.data['vendorId'] ?? '',
        itemName: doc.data['itemName'] ?? '',
        itemLogo: doc.data['itemLogo'] ?? '',
        rating: doc.data['myItemRating'].toDouble() ?? 0.0,
        itemId: doc.data['itemId'] ?? '',
      );
    }).toList();
  }

  Stream<List<RatedItem>> getMyRatedItem(String uid, String vendorId){
    return _ratedItemCollectionReference.where('userId', isEqualTo: uid).where('vendorId', isEqualTo: vendorId).snapshots()
    .map(_ratedItemListFromSnapshot);
  }

  Future<String> getReview(String reviewId) async {
    print('in review scene:');
    print(reviewId);
    String review = '';
    await _reviewsCollectionReference.document(reviewId).get().then((docs){
        review = docs.data['review'];
      });
    print('review');
    print(review);
    return review;
  }

  List<Review> _reviewListFromSnapshot(QuerySnapshot snapshot){
    return snapshot.documents.map((doc){
      return Review(
        userId: doc.data['userId'] ?? '',
        vendorId: doc.data['vendorId'] ?? '',
        review: doc.data['review'] ?? '' ,
        reviewId: doc.data['reviewId'] ?? '',
      );
    }).toList();
  }

  Stream<List<Review>> getAllVendorReviews(String vendorId){
    return _reviewsCollectionReference.where('vendorId', isEqualTo: vendorId).snapshots()
    .map(_reviewListFromSnapshot);
  }

  // do ratings
  Future<String> sendRatings(String uid, List<Map> itemRatings, String vendorName, String vendorLogo, String vendorId, String review, double vendorRating) async {
    // convert all the data to JSON
    // print('bc');
    String checkIfExists = await getRatedVendorId(uid, vendorId);
      if(checkIfExists == ''){
      int noOfItems = itemRatings.length;
      String reviewId = '';

      if (noOfItems > 0){
        if (review.isNotEmpty){
          // send review 
          Review rev = Review(userId: uid, vendorId: vendorId, review: review);
          try{
            final resp = await _reviewsCollectionReference.add(rev.toJSON());
            reviewId = resp.documentID;
          }catch(e){
            print(e.toString());
            
          }
          // add review Id:
          await _reviewsCollectionReference.document(reviewId).updateData({'reviewId': reviewId});
        }
        RatedVendor ven = RatedVendor(userId: uid, vendorId: vendorId, vendorName: vendorName, vendorLogo: vendorLogo, reviewId: reviewId, rating: vendorRating);
        try {
          final resp = await _ratedVendorCollectionReference.add(ven.toJSON());
          String ratedVendorId = resp.documentID;
          await _ratedVendorCollectionReference.document(ratedVendorId).updateData({'ratedVendorId': ratedVendorId});
          // print('done');
        } catch (e) {
          print(e.toString());
        }

        try {
          final resp2 = await _vendorCollectionReference.document(vendorId).collection('ratedVendor').add(ven.toJSON());
          String vendorColratedVendorId = resp2.documentID;
          await _vendorCollectionReference.document(vendorId).collection('ratedVendor').document(vendorColratedVendorId).updateData({'myId': vendorColratedVendorId});
        } catch (e) {
          print(e.toString());
        }

        itemRatings.forEach((item) async{
          RatedItem it = RatedItem(userId: uid, vendorId: vendorId, itemId: item['itemId'], itemName: item['name'], itemLogo: item['logo'], rating: item['givenRating']);
          try {
            final resp = await _ratedItemCollectionReference.add(it.toJSON());
            String ratedItemId = resp.documentID;
            await _ratedItemCollectionReference.document(ratedItemId).updateData({'ratedItemId': ratedItemId});

            final resp2 = await _itemCollectionReference.document(item['itemId']).collection('ratedItem').add(it.toJSON());
            String itemColratedVendorId = resp2.documentID;
            await _itemCollectionReference.document(item['itemId']).collection('ratedItem').document(itemColratedVendorId).updateData({'myId': itemColratedVendorId});

          } catch (e) {
            print(e.toString());
          }
        });
        return null;
      }
      else{
        return 'No items were rated.';
      }
    }else{
      return 'Error: Add a rating failed. User has already rated the vendor';
    }
  }

  // edit rating 

  // getting document ids

  Future<String> getRatedVendorId(String userId, String vendorId) async {
    String docId = '';
    await _ratedVendorCollectionReference.where('userId', isEqualTo: userId).where('vendorId', isEqualTo: vendorId).getDocuments()
    .then((docs){
      if (docs.documents.isNotEmpty){
        docId = docs.documents[0].data['ratedVendorId'];
      }
    });
    return docId;
  }

  Future<String> getRatedItemsDocumentId(String userId, String vendorId, String itemId) async {
    String docId = '';
    await _ratedVendorCollectionReference.where('userId', isEqualTo: userId).where('vendorId', isEqualTo: vendorId).where('itemId', isEqualTo: itemId)
    .getDocuments().then((docs){
          if (docs.documents.isNotEmpty){
            docId = docs.documents[0].data['ratedItemId'];
          }
    });
    return docId;
  }

  Future<String> getVendorSubCollId(String uid, String vendorId) async {
    String docId = '';
    await Firestore.instance.collection('Vendor').document(vendorId).collection('ratedVendor').where('userId', isEqualTo: uid).getDocuments()
    .then((docs){
      if (docs.documents.isNotEmpty){
        docId = docs.documents[0].data['myId'];
      }
    });
    return docId;
  }

  Future<String> getItemSubCollId(String uid, String itemId) async {
    String docId = '';
    await Firestore.instance.collection('item').document(itemId).collection('itemVendor').where('userId', isEqualTo: uid).getDocuments()
    .then((docs){
      if (docs.documents.isNotEmpty){
        docId = docs.documents[0].data['myId'];
      }
    });
    return docId;
  }

  Future<String> updateRatings(String uid, List<Map> itemRatings, String vendorId, String review, String reviewId, double vendorRating) async {
    // convert all the data to JSON
    int noOfItems = itemRatings.length;
    
    // getting vendorId;
    String ratedVendorId = await getRatedVendorId(uid, vendorId);
    String vendorColratedVendorId = await getVendorSubCollId(uid, vendorId);
    // update review
    if (review.isNotEmpty){
      // update review 
      try{
        await _reviewsCollectionReference.document(reviewId).updateData({'review': review});
      }catch(e){
        return e.toString();
      }
    }

    // update rated vendor
    try {
      await _ratedVendorCollectionReference.document(ratedVendorId).updateData({'myVendorRating': vendorRating});
      await Firestore.instance.collection('Vendor').document(vendorId).collection('ratedVendor').document(vendorColratedVendorId).updateData({'myVendorRating': vendorRating});
    } catch (e) {
      return e.toString();
    }

    // update rated item
    if (noOfItems > 0){
      itemRatings.forEach((item) async{
        try {
          // get item id 
          String ratedItemId = await getRatedItemsDocumentId(uid, vendorId, item['itemId']);
          String itemColratedVendorId = await getItemSubCollId(uid, item['itemId']);
          await _ratedItemCollectionReference.document(ratedItemId).updateData({'myItemRating': item['givenRating']});
          await Firestore.instance.collection('item').document(item['itemId']).collection('itemVendor').document(itemColratedVendorId).updateData({'myItemRating': item['givenRating']});
          return null;
        } catch (e) {
          return e.toString();
        }
      });
    }
    return null;
  }

  // host it 
  List<Event> _eventListFromSnapshot(QuerySnapshot snapshot){
    return  snapshot.documents.map((doc){
      return Event(
        coverimage: doc.data['coverimage'],
        eventID: doc.data['eventID'],
       //enddate: doc.data['enddate'],
        name: doc.data['name'],
        //startdate: doc.data['startdate'],
        invitecode: doc.data['invitecode'],
        location1: doc.data['location1'],
        logo: doc.data['logo'],
        uid:doc.data['uid'],
      );
    }).toList();
  }

  Stream<List<Event>> getEventInfo(String eventID) {
    return _eventCollectionReference.snapshots()
    .map(_eventListFromSnapshot);
  }

  Stream<List<Event>> getEventsInfo(String userId){ //each vendor's all item query
    return _eventCollectionReference.where('uid', isEqualTo: 'aDsAvwk0mbgV1CQSUI5wJbU75Zt2').snapshots()
    .map(_eventListFromSnapshot);
  }

}