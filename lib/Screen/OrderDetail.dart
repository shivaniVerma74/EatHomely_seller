import 'dart:async';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:homely_seller/Helper/AppBtn.dart';
import 'package:homely_seller/Helper/Color.dart';
import 'package:homely_seller/Helper/Session.dart';
import 'package:homely_seller/Helper/String.dart';
import 'package:homely_seller/Model/OrdersModel/OrderItemsModel.dart';
import 'package:homely_seller/Model/OrdersModel/OrderModel.dart';
import 'package:homely_seller/Model/Person/PersonModel.dart';
import 'package:homely_seller/Screen/Home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';

import 'WebviewExample.dart';

class OrderDetail extends StatefulWidget {
  final Order_Model? model;
  // final Function? updateHome;
  final String? id;

  const OrderDetail({
    Key? key,
    this.model,
    // this.updateHome,
    this.id,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateOrder();
  }
}

List<PersonModel> delBoyList = [];

class StateOrder extends State<OrderDetail> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController controller = new ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;

  String? deliverBoy;
  var selectStatus;
  Order_Model? model;
  String? pDate, prDate, sDate, dDate, cDate, rDate;

  List<String> statusList = [
    // PROCESSED,
    // PLACED,
    PROCESSED,
    // SHIPED,
    // DELIVERD,
    // READYFORPICKUP,
    // CANCLED,
    // RETURNED,
  ];

  List<String> statusList2 = [
    // PROCESSED,
    READYFORPICKUP,
    // PLACED,
    // PROCESSED,
    // SHIPED,
    DELIVERD,
    PAYMENTCOMPLETE,
    // CANCLED,
    // RETURNED,
  ];

  bool isLoading = true;
  String cgst = '';
  String sgst = '';

  List<Order_Model> tempList = [];
  bool? _isCancleable, _isReturnable;
  bool _isProgress = false;
  String? curStatus;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController? otpC;
  final List<DropdownMenuItem> items = [];
  List<PersonModel> searchList = [];
  // String? selectedValue;
  int? selectedDelBoy;
  final TextEditingController _controller = TextEditingController();
  StateSetter? delBoyState;
  bool fabIsVisible = true;

  @override
  void initState() {
    // getDeliveryBoy();
    for (int i = 0; i < widget.model!.itemList!.length; i++) {
      widget.model!.itemList![i].curSelected =
          widget.model!.itemList![i].status;
     // selectStatus = widget.model!.itemList![i].status?? null;
      print("${widget.model!.itemList![i].status}"+"((((((((((((((((((((((((((");
    }
    Future.delayed(Duration.zero, this.getOrderDetail);

    if(widget.model!.itemList![0].status=="processed"){
      statusList2.clear();
      statusList2.add(READYFORPICKUP);
      //statusList2.add(PAYMENTCOMPLETE);
    }

    if(widget.model!.itemList![0].status=="food ready for pickup"){
      statusList2.clear();
      statusList2.add(DELIVERD);
      //statusList2.add(PAYMENTCOMPLETE);
    }
    print("-------- ----------- ${widget.model!.itemList![0]}");
    if(widget.model!.itemList![0].status==PAYMENTCOMPLETE){
      statusList2.clear();
     //  statusList2.add(DELIVERD);
     //   statusList2.add(PAYMENTCOMPLETE);
    }
    if(widget.model!.itemList![0].status==DELIVERD){
      statusList2.clear();
    //    statusList2.add(DELIVERD);
       statusList2.add(PAYMENTCOMPLETE);
    }

    super.initState();

    // Future.delayed(Duration(milliseconds: 300),(){
    //   return getTotalTax();
    // });

    controller = ScrollController();
    controller.addListener(
      () {
        setState(
          () {
            fabIsVisible = controller.position.userScrollDirection ==
                ScrollDirection.forward;
          },
        );
      },
    );
    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = new Tween(
      begin: width * 0.7,
      end: 50.0,
    ).animate(
      new CurvedAnimation(
        parent: buttonController!,
        curve: new Interval(
          0.0,
          0.150,
        ),
      ),
    );
    _controller.addListener(
      () {
        searchOperation(_controller.text);
      },
    );
  }

//==============================================================================
//========================= getDeliveryBoy API =================================

  Future<void> getDeliveryBoy() async {
    CUR_USERID = await getPrefrence(Id);
    var parameter = {
      SellerId: CUR_USERID,
    };

    print("checking parameter here $getDeliveryBoysApi and $parameter");
    apiBaseHelper.postAPICall(getDeliveryBoysApi, parameter).then(
      (getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          delBoyList.clear();
          var data = getdata["data"];
          delBoyList = (data as List)
              .map((data) => new PersonModel.fromJson(data))
              .toList();
        } else {
          setSnackbar(msg!);
        }
      },
      onError: (error) {
        setSnackbar(error.toString());
      },
    );
  }

  Future<Null> getOrderDetail() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      CUR_USERID = await getPrefrence(Id);
      var parameter = {
        SellerId: CUR_USERID,
        Id: widget.id,
      };
      print("checking order detail here now $getOrdersApi and $parameter");
      apiBaseHelper.postAPICall(getOrdersApi, parameter).then(
        (getdata) async {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];
            sgst = data[0]['cgst'];
            cgst = data[0]['sgst'];
            if (sgst == "") {
              totalTax = 0.0;
            } else {
              totalTax = double.parse(sgst.toString()) + double.parse(cgst.toString());
            }
            print("checking data here now final $sgst and $sgst");
            if (data.length != 0) {
              searchList.clear();
              tempList = (data as List).map((data) => new Order_Model.fromJson(data)).toList();
              for (int i = 0; i < tempList[0].itemList!.length; i++)
                tempList[0].itemList![i].curSelected = tempList[0].itemList![i].status;
              searchList.addAll(delBoyList);
              if (tempList[0].itemList![0].deliveryBoyId != null)
                selectedDelBoy = delBoyList.indexWhere((f) => f.id == tempList[0].itemList![0].deliveryBoyId);
              if (selectedDelBoy == -1) selectedDelBoy = null;
              if (tempList[0].payMethod == "Bank Transfer") {
                statusList.removeWhere((element) => element == PLACED);
              }
              curStatus = tempList[0].itemList![0].activeStatus!;
              if (tempList[0].listStatus!.contains(PLACED)) {
                pDate = tempList[0].listDate![tempList[0].listStatus!.indexOf(PLACED)];
                if (pDate != null) {
                  List d = pDate!.split(" ");
                  pDate = d[0] + "\n" + d[1];
                }
              }
              if (tempList[0].listStatus!.contains(PROCESSED)) {
                prDate = tempList[0]
                    .listDate![tempList[0].listStatus!.indexOf(PROCESSED)];
                if (prDate != null) {
                  List d = prDate!.split(" ");
                  prDate = d[0] + "\n" + d[1];
                }
              }
              if (tempList[0].listStatus!.contains(SHIPED)) {
                sDate = tempList[0]
                    .listDate![tempList[0].listStatus!.indexOf(SHIPED)];
                if (sDate != null) {
                  List d = sDate!.split(" ");
                  sDate = d[0] + "\n" + d[1];
                }
              }
              if (tempList[0].listStatus!.contains(DELIVERD)) {
                dDate = tempList[0]
                    .listDate![tempList[0].listStatus!.indexOf(DELIVERD)];
                if (dDate != null) {
                  List d = dDate!.split(" ");
                  dDate = d[0] + "\n" + d[1];
                }
              }
              if (tempList[0].listStatus!.contains(CANCLED)) {
                cDate = tempList[0]
                    .listDate![tempList[0].listStatus!.indexOf(CANCLED)];
                if (cDate != null) {
                  List d = cDate!.split(" ");
                  cDate = d[0] + "\n" + d[1];
                }
              }
              if (tempList[0].listStatus!.contains(RETURNED)) {
                rDate = tempList[0]
                    .listDate![tempList[0].listStatus!.indexOf(RETURNED)];
                if (rDate != null) {
                  List d = rDate!.split(" ");
                  rDate = d[0] + "\n" + d[1];
                }
              }
              model = tempList[0];
              _isCancleable = model!.isCancleable == "1" ? true : false;
              _isReturnable = model!.isReturnable == "1" ? true : false;
              //getTotalTax();
            } else {
              setSnackbar(msg!);
            }
            setState(
              () {
                isLoading = false;
              },
            );
          } else {}
        },
        onError: (error) {
          //  setSnackbar(error.toString());
        },
      );
    } else {
      if (mounted)
        setState(
          () {
            _isNetworkAvail = false;
          },
        );
    }
    return null;
  }

  double totalTax = 0;

  getTotalTax() {
    print("total gstttsts ${model!.igst}");
    if (model!.igst == "" || model!.igst == null) {
      totalTax = 0.0;
    } else {
      totalTax = double.parse(model!.igst.toString()) +
          double.parse(model!.igst.toString());
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            noIntImage(),
            noIntText(context),
            noIntDec(context),
            AppBtn(
              title: getTranslated(context, "TRY_AGAIN_INT_LBL")!,
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();
                Future.delayed(Duration(seconds: 2)).then(
                  (_) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => super.widget));
                    } else {
                      await buttonController!.reverse();
                      setState(
                        () {},
                      );
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: lightWhite,
      appBar: getAppBar(getTranslated(context, "ORDER_DETAIL")!, context),
      // floatingActionButton: AnimatedOpacity(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: [
      //       FloatingActionButton(
      //         backgroundColor: white,
      //         child: Image.asset(
      //           'assets/images/whatsapp.png',
      //           width: 25,
      //           height: 25,
      //           color: primary,
      //         ),
      //         onPressed: () async {
      //           String text =
      //               'Hello ${tempList[0].name},\nYour order with id : ${tempList[0].id} is ${tempList[0].itemList![0].activeStatus}. If you have further query feel free to contact us.Thank you.';
      //           await launch(
      //               "https://wa.me/${tempList[0].countryCode! + "" + tempList[0].mobile!}?text=$text");
      //         },
      //         heroTag: null,
      //       ),
      //       SizedBox(
      //         height: 10,
      //       ),
      //       FloatingActionButton(
      //         backgroundColor: white,
      //         child: Icon(
      //           Icons.message,
      //           color: primary,
      //         ),
      //         onPressed: () async {
      //           String text =
      //               'Hello ${tempList[0].name},\nYour order with id : ${tempList[0].id} is ${tempList[0].itemList![0].activeStatus}. If you have further query feel free to contact us.Thank you.';
      //
      //           var uri = 'sms:${tempList[0].mobile}?body=$text';
      //           await launch(uri);
      //         },
      //         heroTag: null,
      //       )
      //     ],
      //   ),
      //   duration: Duration(milliseconds: 100),
      //   opacity: fabIsVisible ? 1 : 0,
      // ),
      body: _isNetworkAvail
          ? Stack(
              children: [
                isLoading
                    ? shimmer()
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              controller: controller,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Card(
                                      elevation: 0,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        padding: EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  getTranslated(context,
                                                          "ORDER_ID_LBL")! +
                                                      " - ",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: grey),
                                                ),
                                                Text(
                                                  model!.id!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: black),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  getTranslated(context,
                                                          "ORDER_DATE")! +
                                                      " - ",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: grey),
                                                ),
                                                Text(
                                                  model!.orderDate!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: black),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  "Order Time" + " - ",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: grey),
                                                ),
                                                Text(
                                                  model!.orderTime!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: black),
                                                ),
                                              ],
                                            ),
                                            model!.deliverTime != ""
                                                ? Row(
                                                    children: [
                                                      // Text(
                                                      //   "Delivered Time" +
                                                      //       " - ",
                                                      //   style: Theme.of(context)
                                                      //       .textTheme
                                                      //       .subtitle2!
                                                      //       .copyWith(color: grey),
                                                      // ),
                                                      // Text(
                                                      //   model!.deliverTime.toString(),
                                                      //   style: Theme.of(context)
                                                      //       .textTheme
                                                      //       .subtitle2!
                                                      //       .copyWith(color: black),
                                                      // ),
                                                    ],
                                                  )
                                                : SizedBox.shrink(),
                                            Row(
                                              children: [
                                                Text(
                                                  getTranslated(context, "PAYMENT_MTHD")! + " - ",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: grey),
                                                ),
                                                model!.payMethod! == "UPI" ?
                                                Text(
                                                  "Pay After Delivery",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: black),
                                                ):  Text(
                                                  "All Ready Paid",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: black),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text("Delivery Method -",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: grey),
                                                ),
                                                widget.model?.deliveryType == "2" ?
                                                Text(
                                                  "Delivery Agent",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: black),
                                                ): Text(
                                                  "self Pick up",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: black),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text("Order Method -",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(color: grey),
                                                ),
                                                Text(
                                                  model!.urgentDelivery!,
                                                  style: Theme.of(context).textTheme.subtitle2!.copyWith(color: black),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text("Schedule Delivery Date -",
                                                  style: Theme.of(context).textTheme.subtitle2!.copyWith(color: grey),
                                                ),
                                                Text(
                                                  model!.deliveryDate!,
                                                  style: Theme.of(context).textTheme.subtitle2!.copyWith(color: black),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    model!.delDate != null &&
                                            model!.delDate!.isNotEmpty
                                        ? Card(
                                            elevation: 0,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: Text(
                                                getTranslated(context,
                                                        "PREFER_DATE_TIME")! +
                                                    ": " +
                                                    model!.delDate! +
                                                    " - " +
                                                    model!.delTime!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle2!
                                                    .copyWith(
                                                        color: lightBlack2),
                                              ),
                                            ),
                                          )
                                        : Container(),

                                    //iteam's here
                                    widget.model?.deliveryType == "2" ?
                                    Card(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 10, top: 6),
                                            child:
                                                Text("Update Order Status"),
                                          ),
                                          // SizedBox(
                                          //   height: 5,
                                          // ),
                                          widget.model!.itemList![0].status != 'food prepared' ?
                                          Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Padding(
                                                          padding: const EdgeInsets.only(right: 8.0, left: 8),
                                                               child: DropdownButtonFormField(
                                                                 dropdownColor: white,
                                                                 isDense: true,
                                                                 iconEnabledColor: primary,
                                                                 hint: Text(
                                                                   getTranslated(context, "UpdateStatus")!,
                                                                   style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                                                                       color: primary, fontWeight: FontWeight.bold),
                                                                 ),
                                                                 decoration: InputDecoration(
                                                                   filled: true,
                                                                   isDense: true,
                                                                   fillColor: white,
                                                                   contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                                                   enabledBorder: OutlineInputBorder(
                                                                     borderSide: BorderSide(color: primary),
                                                                   ),
                                                                 ),
                                                                 value: selectStatus,
                                                                 onChanged: (dynamic newValue) {
                                                                   setState(
                                                                         () {
                                                                       widget.model!.itemList![0].curSelected = newValue;

                                                                     },
                                                                   );
                                                                 },
                                                                 items: statusList.map(
                                                                       (String st) {
                                                                     return DropdownMenuItem<
                                                                         String>(
                                                                       value: st,
                                                                       child:
                                                                       st == "shipped"
                                                                           ? Text(
                                                                         "Picked Up",
                                                                         style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                                       )
                                                                           :
                                                                       st == "processed"
                                                                           ? Text(
                                                                         "Food Ready for Pikcup",
                                                                         style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                                       ): Text(
                                                                         capitalize(st),
                                                                         style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                                       ),
                                                                     );
                                                                   },
                                                                 ).toList(),
                                                               ),
                                                          //      DropdownButtonFormField(
                                                          //       dropdownColor: white,
                                                          //       isDense: true,
                                                          //       iconEnabledColor: primary,
                                                          //       hint: Text(
                                                          //       getTranslated(context, "UpdateStatus")!,
                                                          //       style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                                                          //             color: primary,
                                                          //             fontWeight: FontWeight.bold),
                                                          //   ),
                                                          //   decoration: InputDecoration(
                                                          //     filled: true,
                                                          //     isDense: true,
                                                          //     fillColor: white,
                                                          //     contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                                          //     enabledBorder: OutlineInputBorder(
                                                          //       borderSide: BorderSide(color: primary),
                                                          //     ),
                                                          //   ),
                                                          //   value: selectStatus,
                                                          //   onChanged: (dynamic newValue) {
                                                          //     setState(
                                                          //       () {
                                                          //         widget.model!.itemList![0].curSelected = newValue;
                                                          //
                                                          //       },
                                                          //     );
                                                          //   },
                                                          //   items: statusList.map(
                                                          //     (String st) {
                                                          //       // String dropdownValue;
                                                          //       // String displayText;
                                                          //
                                                          //       // if (st == "shipped") {
                                                          //       //   dropdownValue = "shipped";
                                                          //       //   displayText = "Picked Up";
                                                          //       // } else
                                                          //       //   if (st == "processed") {
                                                          //       //   dropdownValue = "processed";
                                                          //       //   displayText = "Preparing";
                                                          //       // } else {
                                                          //       //   dropdownValue = st;
                                                          //       //   displayText = capitalize(st);
                                                          //       // }
                                                          //       return DropdownMenuItem<
                                                          //           String>(
                                                          //         value: st,
                                                          //         child:
                                                          //         st == "shipped"
                                                          //             ? Text(
                                                          //                 "Picked Up",
                                                          //                 style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                          //               )
                                                          //             : st == "processed"
                                                          //                 ? Text(
                                                          //                     "Preparing",
                                                          //                     style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                          //                   )
                                                          //                 :
                                                          //         Text(
                                                          //           capitalize(st),
                                                          //                     style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                          //                   ),
                                                          //       );
                                                          //     },
                                                          //   ).toList(),
                                                          // ),
                                                        ),
                                                      ),
                                                      RawMaterialButton(
                                                        constraints: const BoxConstraints.expand(width: 42, height: 42),
                                                        onPressed: () {
                                                          print("firsttsst${widget.model!.itemList![0].curSelected}===========");
                                                          print("second${widget.model!.itemList![0].status}===========");
                                                          // if(widget.model!.itemList![0].status?.toLowerCase()=="food ready for pickup"){
                                                            updateOrder(
                                                              widget.model!.itemList![0].curSelected,
                                                              updateOrderItemApi,
                                                              widget.model!.itemList![0].id,
                                                              true,
                                                              0,
                                                            );
                                                          // }else{
                                                          //   Fluttertoast.showToast(msg: 'Status Already Update');
                                                          // }
                                                          // if(widget.model!.itemList![0].curSelected?.toLowerCase() == widget.model!.itemList![0].status?.toLowerCase()) {
                                                          //   Fluttertoast.showToast(msg: 'choose different status');
                                                          // } else {
                                                          //   updateOrder(
                                                          //     widget.model!.itemList![0].curSelected,
                                                          //     updateOrderItemApi,
                                                          //     widget.model!.itemList![0].id,
                                                          //     true,
                                                          //     0,
                                                          //   );
                                                          // }
                                                          // if (widget.model!.itemList![0].item_otp != null &&
                                                          //     widget.model!.itemList![0].item_otp!.isNotEmpty &&
                                                          //     widget.model!.itemList![0].item_otp != "0" &&
                                                          //     widget.model!.itemList![0].curSelected == DELIVERD) {
                                                          //   otpDialog(
                                                          //       widget.model!.itemList![0].curSelected,
                                                          //       widget.model!.otp,
                                                          //       model.id, true, 0);
                                                          // } else {
                                                          //   updateOrder(
                                                          //       widget.model!.itemList![0].curSelected,
                                                          //       model.id, true, 0,
                                                          //       widget.model!.itemList![0].item_otp);
                                                          // }
                                                        },
                                                        elevation: 2.0,
                                                        fillColor: fontColor,
                                                        padding: const EdgeInsets.only(left: 5),
                                                        child: const Align(
                                                          alignment: Alignment.center,
                                                          child: Icon(
                                                            Icons.send,
                                                            size: 20,
                                                            color: white,
                                                          ),
                                                        ),
                                                        shape: const CircleBorder(),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Container(
                                               width: MediaQuery.of(context).size.width/1,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child: Text(
                                                      "Food Ready For Pickup",
                                                      style: TextStyle(
                                                          color: primary),
                                                    ),
                                                ),
                                              ),
                                        ],
                                      ),
                                    ): SizedBox(),
                                    widget.model?.deliveryType == "1" ?  Container(
                                      child: Card(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(left: 10, top: 6),
                                              child:
                                              Text("Update Order Status"),
                                            ),
                                            // SizedBox(
                                            //   height: 5,
                                            // ),
                                            widget.model!.itemList![0].status != 'Payment Complete' ?
                                            Padding(
                                                 padding: const EdgeInsets.symmetric(vertical: 10.0),
                                                 child: Row(
                                                 children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(right: 8.0, left: 8),
                                                      child: DropdownButtonFormField(
                                                        dropdownColor: white,
                                                        isDense: true,
                                                        iconEnabledColor: primary,
                                                        hint: Text(
                                                          getTranslated(context, "UpdateStatus")!,
                                                          style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                                                              color: primary, fontWeight: FontWeight.bold),
                                                        ),
                                                        decoration: InputDecoration(
                                                          filled: true,
                                                          isDense: true,
                                                          fillColor: white,
                                                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(color: primary),
                                                          ),
                                                        ),
                                                        value: selectStatus,
                                                        onChanged: (dynamic newValue) {
                                                          setState(
                                                                () {
                                                                  selectStatus = newValue ;
                                                                    widget.model!.itemList![0].curSelected = newValue;

                                                            },
                                                          );
                                                        },
                                                        items: statusList2.map(
                                                              (String st) {
                                                            return DropdownMenuItem<
                                                                String>(
                                                              value: st,
                                                              child: st == "shipped"
                                                                  ? Text(
                                                                "Picked Up",
                                                                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                              )
                                                                  : st == "processed"
                                                                  ? Text(
                                                                "Food Ready for Pikcup",
                                                                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                              )
                                                                  : Text(
                                                                capitalize(st),
                                                                style: Theme.of(this.context).textTheme.subtitle2!.copyWith(color: primary, fontWeight: FontWeight.bold),
                                                              ),
                                                            );
                                                          },
                                                        ).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                   RawMaterialButton(
                                                     constraints: const BoxConstraints.expand(width: 42, height: 42),
                                                     onPressed: () {
                                                       // updateOrder(
                                                       //   widget.model!.itemList![0].curSelected,
                                                       //   updateOrderItemApi,
                                                       //   widget.model!.itemList![0].id,
                                                       //   true,
                                                       //   0,
                                                       // );
                                                       if (widget.model!.itemList![0].curSelected == DELIVERD) {
                                                         otpDialog(
                                                             widget.model!.itemList![0].curSelected,
                                                             widget.model!.otp, widget.model!.itemList![0].id, true, 0);
                                                       }
                                                       // else {
                                                       //   if(widget.model!.itemList![0].curSelected?.toLowerCase() == widget.model!.itemList![0].status?.toLowerCase()) {
                                                       //     Fluttertoast.showToast(msg: 'choose different status');
                                                       //   }
                                                         else {
                                                           updateOrder(
                                                             widget.model!.itemList![0].curSelected,
                                                             updateOrderItemApi,
                                                             widget.model!.itemList![0].id,
                                                             true,
                                                             0,
                                                           );
                                                         }
                                                       // }
                                                     },
                                                     elevation: 2.0,
                                                     fillColor: fontColor,
                                                     padding: const EdgeInsets.only(left: 5),
                                                     child: const Align(
                                                       alignment: Alignment.center,
                                                       child: Icon(
                                                         Icons.send,
                                                         size: 20,
                                                         color: white,
                                                       ),
                                                     ),
                                                     shape: const CircleBorder(),
                                                   ),
                                                ],
                                              ),
                                            ): Container(
                                              width: MediaQuery.of(context).size.width/1,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Text(
                                              "Payment Complete",
                                              style: TextStyle(
                                                      color: primary),
                                                    ),
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ),
                                    ) : SizedBox(),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: model!.itemList!.length,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, i) {
                                        OrderItem orderItem =
                                            model!.itemList![i];
                                        print(
                                            "order item here now go there ${model!.itemList![i].addonList!.length}");
                                        return productItem(
                                            orderItem, model!, i);
                                      },
                                    ),
                                    // Add-on item section
                                    model!.addonList?.isEmpty ?? true
                                        ? SizedBox()
                                        : Container(
                                            decoration: BoxDecoration(color: Colors.white),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10, bottom: 10),
                                                  child: Text("Addon Items"),
                                                ),
                                                Container(
                                                  child: ListView.separated(
                                                      separatorBuilder: (c, i) {
                                                        return Divider();
                                                      },
                                                      physics:
                                                          NeverScrollableScrollPhysics(),
                                                      shrinkWrap: true,
                                                      itemCount: model!
                                                          .addonList!.length,
                                                      itemBuilder: (c, i) {
                                                        return ListTile(
                                                          leading: Container(
                                                            height: 50,
                                                            width: 50,
                                                            child:
                                                                Image.network(
                                                              "${model!.addonList![i].image}",
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                          title: Text(
                                                              "${model!.addonList![i].name}"),
                                                          subtitle: Text(
                                                              "\u{20B9} ${model!.addonList![i].price}"),
                                                          trailing: Text(
                                                              "Qty ${model!.addonList![i].quantity}"),
                                                        );
                                                      }),
                                                ),
                                              ],
                                            ),
                                          ),

                                    //complete
                                    model!.payMethod == "Bank Transfer"
                                        ? bankProof(model!)
                                        : Container(),
                                    // shippingDetails(),
                                    delPermission == '1'
                                        ? driverDetails()
                                        : Container(),
                                    priceDetails(),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                         InkWell(
                                           onTap: () {
                                             print("https://developmentalphawizz.com/eatoz_clone/home/edit_orders?edit_id=${widget.id}&seller_id=$CUR_USERID&type=cook");
                                             launchUrl(Uri.parse('https://developmentalphawizz.com/eatoz_clone/home/edit_orders?edit_id=${widget.id}&seller_id=$CUR_USERID&type=cook'),mode: LaunchMode.externalApplication);
                                           },
                                           child: Container(
                                             height: 40,
                                             width: 130,
                                             decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Color(0xff814030),
                                             ),
                                             child: Center(child: Text("Cooking Slip", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),)),
                                             ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              print("seller id is nowww $CUR_USERID");
                                              launchUrl(Uri.parse('https://developmentalphawizz.com/eatoz_clone/home/edit_orders?edit_id=${widget.id}&seller_id=$CUR_USERID&type=cook&types=customer'),mode: LaunchMode.externalApplication);
                                              // print("workinggg===========");
                                              // Navigator.push(context,
                                              //     MaterialPageRoute(builder: (context) {
                                              //       return WebViewExample(
                                              //           url:
                                              //           "https://developmentalphawizz.com/eatoz_clone/home/edit_orders?edit_id=${widget.id}&seller_id=$CUR_USERID&type=cook&types=customer");
                                              //     }));
                                            },
                                            child: Container(
                                              height: 40,
                                              width: 150,
                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Color(0xff814030),
                                              ),
                                              child: Center(child: Text("Customer Cooking Slip", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                showCircularProgress(_isProgress, primary),
              ],
            )
          : noInternet(context),
    );
  }

  otpDialog(String? curSelected, String? otp, String? id, bool item, int index) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
                print('___________${otp}_____fdffd_____');
                return AlertDialog(
                  contentPadding: const EdgeInsets.all(0.0),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  content: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                                padding:
                                const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                                child: Text(
                                  "OTP Confirm",
                                  style: Theme.of(this.context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(color: fontColor),
                                )),
                            const Divider(color: lightBlack),
                            Form(
                                key: _formkey,
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            20.0, 0, 20.0, 0),
                                        child: TextFormField(
                                          keyboardType: TextInputType.number,
                                          validator: (String? value) {
                                            if (value!.isEmpty) {
                                              return "This Field is Required";
                                            } else if (value.trim() != otp) {
                                              return 'Error validating OTP, try again';
                                            } else {
                                              return null;
                                            }
                                          },
                                          autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                          decoration: InputDecoration(
                                            hintText: "Enter OTP",
                                            hintStyle: Theme.of(this.context)
                                                .textTheme
                                                .subtitle1!
                                                .copyWith(
                                                color: lightBlack,
                                                fontWeight: FontWeight.normal),
                                          ),
                                          controller: otpC,
                                        )),
                                  ],
                                ))
                          ])),
                  actions: <Widget>[
                    TextButton(
                        child: Text(
                          "Cancel",
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                              color: lightBlack, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    TextButton(
                        child: Text(
                          "Send",
                          style: Theme.of(this.context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                              color: fontColor, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final form = _formkey.currentState!;
                          if (form.validate()) {
                            form.save();
                            setState(() {
                              Navigator.pop(context);
                            });
                            updateOrder(
                              widget.model!.itemList![0].curSelected,
                              updateOrderItemApi,
                              widget.model!.itemList![0].id,
                              true,
                              0,
                            );
                          }
                        })
                  ],
                );
              });
        });
  }


  Future<void> searchOperation(String searchText) async {
    searchList.clear();
    for (int i = 0; i < delBoyList.length; i++) {
      PersonModel map = delBoyList[i];
      if (map.name!.toLowerCase().contains(searchText)) {
        searchList.add(map);
      }
    }

    if (mounted) delBoyState!(() {});
  }

  Future<void> delboyDialog(String status, int index) async {
    int itemindex = index;
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            delBoyState = setStater;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    5.0,
                  ),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                    child: Text(
                      "Select Rider",
                      // getTranslated(context, "SELECTDELBOY")!,
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle1!
                          .copyWith(color: fontColor),
                    ),
                  ),
                  TextField(
                    controller: _controller,
                    autofocus: false,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                      prefixIcon: Icon(Icons.search, color: primary, size: 17),
                      hintText: getTranslated(context, "Search")!,
                      hintStyle: TextStyle(color: primary.withOpacity(0.5)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: white),
                      ),
                    ),
                  ),
                  Divider(color: lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: () {
                          return searchList.asMap().map(
                                (index, element) => MapEntry(index,
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      isLoading = true;
                                      if (mounted) {
                                        selectedDelBoy = index;
                                        updateOrder(status, updateOrderItemApi,
                                            model!.id, true, itemindex);
                                        setState(
                                          () {
                                            deliverBoy = searchList[index].name!;
                                          },
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: double.maxFinite,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          searchList[index].name!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ).values.toList();
                        }(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  List<Widget> getLngList() {
    return searchList
        .asMap()
        .map(
          (index, element) => MapEntry(
            index,
            InkWell(
              onTap: () {
                if (mounted)
                  setState(() {
                    selectedDelBoy = index;
                    Navigator.of(context).pop();
                  });
              },
              child: Container(
                width: double.maxFinite,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    searchList[index].name!,
                  ),
                ),
              ),
            ),
          ),
        ).values.toList();
  }

  // otpDialog(String? curSelected, String? otp, String? id, bool item, int index) async {
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setStater) {
  //           return AlertDialog(
  //             contentPadding: const EdgeInsets.all(0.0),
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.all(Radius.circular(5.0))),
  //             content: SingleChildScrollView(
  //                 scrollDirection: Axis.vertical,
  //                 child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Padding(
  //                           padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
  //                           child: Text(
  //                             getTranslated(context, "OTP_LBL")!,
  //                             style: Theme.of(this.context)
  //                                 .textTheme
  //                                 .subtitle1!
  //                                 .copyWith(color: fontColor),
  //                           )),
  //                       Divider(color: lightBlack),
  //                       Form(
  //                           key: _formkey,
  //                           child: new Column(
  //                             children: <Widget>[
  //                               Padding(
  //                                   padding:
  //                                       EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
  //                                   child: TextFormField(
  //                                     keyboardType: TextInputType.number,
  //                                     validator: (String? value) {
  //                                       if (value!.length == 0)
  //                                         return getTranslated(
  //                                             context, "FIELD_REQUIRED")!;
  //                                       else if (value.trim() != otp)
  //                                         return getTranslated(
  //                                             context, "OTPERROR")!;
  //                                       else
  //                                         return null;
  //                                     },
  //                                     autovalidateMode:
  //                                         AutovalidateMode.onUserInteraction,
  //                                     decoration: InputDecoration(
  //                                       hintText: getTranslated(
  //                                           context, "OTP_ENTER")!,
  //                                       hintStyle: Theme.of(this.context)
  //                                           .textTheme
  //                                           .subtitle1!
  //                                           .copyWith(
  //                                               color: lightBlack,
  //                                               fontWeight: FontWeight.normal),
  //                                     ),
  //                                     controller: otpC,
  //                                   )),
  //                             ],
  //                           ))
  //                     ])),
  //             actions: <Widget>[
  //               new MaterialButton(
  //                   child: Text(
  //                     getTranslated(context, "CANCEL")!,
  //                     style: Theme.of(this.context)
  //                         .textTheme
  //                         .subtitle2!
  //                         .copyWith(
  //                             color: lightBlack, fontWeight: FontWeight.bold),
  //                   ),
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                   }),
  //               new MaterialButton(
  //                 child: Text(
  //                   getTranslated(context, "SEND_LBL")!,
  //                   style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
  //                       color: fontColor, fontWeight: FontWeight.bold),
  //                 ),
  //                 onPressed: () {
  //                   final form = _formkey.currentState!;
  //                   if (form.validate()) {
  //                     form.save();
  //                     setState(() {
  //                       Navigator.pop(context);
  //                     });
  //                     updateOrder(
  //                         curSelected, updateOrderItemApi, id, item, index);
  //                   }
  //                 },
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  _launchMap(lat, lng) async {
    var url = '';

    if (Platform.isAndroid) {
      url =
          "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving&dir_action=navigate";
    } else {
      url =
          "http://maps.apple.com/?saddr=&daddr=$lat,$lng&directionsmode=driving&dir_action=navigate";
    }
    await launch(url);
    // if (await canLaunch(url)) {
    //   await launch(url);
    // } else {
    //   throw 'Could not launch $url';
    // }
  }

  priceDetails() {
    print("ok final values are here now ${model!.itemList![0].cgst}");
    return Card(
        elevation: 0,
        child: Padding(
            padding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.only(left: 15.0, right: 15.0),
                  child: Text("Bill Detail",
                      //getTranslated(context, "PRICE_DETAIL")!,
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: primary, fontWeight: FontWeight.bold))),
              Divider(
                color: lightBlack,
              ),
              Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, "PRICE_LBL")! + " " + ":",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2)),
                    Text(
                        CUR_CURRENCY +
                            " " +
                            "${double.parse(tempList[0].subTotal.toString()).toStringAsFixed(2)}",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, "DELIVERY_CHARGE")! + " " + ":",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2)),
                    Text(
                        "+ " +
                            CUR_CURRENCY +
                            " " +
                            "${double.parse(tempList[0].delCharge.toString()).toStringAsFixed(2)}",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2))
                    ],
                  ),
                ),
              // Padding(
              //   padding: EdgeInsets.only(left: 15.0, right: 15.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(
              //           getTranslated(context, "TAXPER")! +
              //               " (" +
              //               tempList[0].taxPer! +
              //               ")" +
              //               " " +
              //               ":",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2)),
              //       Text("+ " + CUR_CURRENCY + " " + tempList[0].taxAmt!,
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2))
              //     ],
              //   ),
              // ),
                  Padding(
                    padding: EdgeInsets.only(left: 15.0, right: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Packaging Charge",
                            style: Theme.of(context)
                                .textTheme
                                .button!
                                .copyWith(color: lightBlack2),),
                        Text("+ " + CUR_CURRENCY + " " + tempList[0].totalPackingCharge!,
                            style: Theme.of(context)
                                .textTheme
                                .button!
                                .copyWith(color: lightBlack2))
                      ],
                    ),
                  ),
               Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        getTranslated(context, "PROMO_CODE_DIS_LBL")! +
                            " " +
                            ":",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2)),
                    Text(
                      "- " +
                          CUR_CURRENCY +
                          " " +
                          "${double.parse(tempList[0].promoDis.toString()).toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.button!.copyWith(
                            color: lightBlack2,
                          ),
                    )
                  ],
                ),
              ),

              ///
              // Padding(
              //   padding: EdgeInsets.only(left: 15.0, right: 15.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text("CGST" + " " + ":",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2)),
              //       Text(CUR_CURRENCY + " " + "${cgst}",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2))
              //     ],
              //   ),
              // ),
              // Padding(
              //   padding: EdgeInsets.only(left: 15.0, right: 15.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text("SGST" + " " + ":",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2)),
              //       Text(CUR_CURRENCY + " " + "${sgst}",
              //           style: Theme.of(context)
              //               .textTheme
              //               .button!
              //               .copyWith(color: lightBlack2))
              //     ],
              //   ),
              // ),
              Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total GST" + " " + ":",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2)),
                    Text(
                        CUR_CURRENCY +
                            " " +
                            "${double.parse(model!.igst.toString()).toStringAsFixed(2)}",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2))
                     ],
                  ),
               ),
              ///
              Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, "WALLET_BAL")! + " " + ":",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2)),
                    Text(
                        "- " +
                            CUR_CURRENCY +
                            " " +
                            "${double.parse(tempList[0].walBal.toString()).toStringAsFixed(2)}",
                        style: Theme.of(context)
                            .textTheme
                            .button!
                            .copyWith(color: lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(getTranslated(context, "PAYABLE")! + " " + ":",
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: lightBlack, fontWeight: FontWeight.bold)),
                    Text(
                        CUR_CURRENCY +
                            " " +
                            "${double.parse(tempList[0].payable.toString()).toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.button!.copyWith(
                            color: lightBlack, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ])));
  }

  driverDetails() {
    return tempList[0].itemList![0].delivery_boy_name != ""
        ? Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: Row(
                        children: [
                          Text("Delivery Boy Details",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.bold)),
                        ],
                      )),
                  Divider(
                    color: lightBlack,
                  ),
                  Padding(
                      padding: EdgeInsets.only(left: 15.0, right: 15.0),
                      child: Text(
                        tempList[0].itemList![0].delivery_boy_name.toString(),
                      )),
                  InkWell(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 5),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.call,
                                size: 15,
                                color: fontColor,
                              ),
                              Text(
                                  " ${tempList[0].itemList![0].deliveryBoyMobile}",
                                  style: const TextStyle(
                                      color: fontColor,
                                      decoration: TextDecoration.underline)),
                            ],
                          )),
                      onTap: () {
                        _launchCaller();
                      }),
                  /*InkWell(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.call,
                      size: 15,
                      color: black,
                    ),
                    Text(" " + tempList[0].mobile!,
                        style: TextStyle(
                            color: primary,
                            decoration: TextDecoration.underline)),
                  ],
                ),
              ),
              onTap: _launchCaller,
            ),*/
                ],
              ),
            ),
          )
        : SizedBox();
  }

  shippingDetails() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0),
                child: Row(
                  children: [
                    Text(getTranslated(context, "SHIPPING_DETAIL")!,
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: primary, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Container(
                      height: 30,
                      child: IconButton(
                          icon: Icon(
                            Icons.location_on,
                            color: primary,
                          ),
                          onPressed: () {
                            _launchMap(
                                tempList[0].latitude, tempList[0].longitude);
                          }),
                    )
                  ],
                )),
            Divider(
              color: lightBlack,
            ),
            Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15.0),
                child: Text(
                  tempList[0].name != null && tempList[0].name!.length > 0
                      ? " " + capitalize(tempList[0].name!)
                      : " ",
                )),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 3),
              child: Text(
                tempList[0].address != null
                    ? capitalize(tempList[0].address!)
                    : "",
                style: TextStyle(color: lightBlack2),
              ),
            ),
            /*InkWell(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.call,
                      size: 15,
                      color: black,
                    ),
                    Text(" " + tempList[0].mobile!,
                        style: TextStyle(
                            color: primary,
                            decoration: TextDecoration.underline)),
                  ],
                ),
              ),
              onTap: _launchCaller,
            ),*/
          ],
        ),
      ),
    );
  }

  productItem(OrderItem orderItem, Order_Model model, int i) {
    List att = [], val = [];
    // List? del;
    if (orderItem.attr_name != null && orderItem.attr_name!.isNotEmpty) {
      att = orderItem.attr_name!.split(',');
      val = orderItem.varient_values!.split(',');
    }
    var index1;
    if (orderItem.deliveryBoyId != null) {
      index1 = searchList
          .indexWhere((element) => element.id == orderItem.deliveryBoyId);
    }
    var orderImage = "";
    if (orderItem.image != null) {
      orderImage = orderItem.image!;
    }

    print("order item here now ${orderItem.addonList!.length}");
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: FadeInImage(
                      fadeInDuration: Duration(milliseconds: 150),
                      image: NetworkImage(orderImage),
                      height: 90.0,
                      width: 90.0,
                      placeholder: placeHolder(90),
                    )),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderItem.name ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(
                                  color: lightBlack,
                                  fontWeight: FontWeight.normal),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        orderItem.attr_name!.isNotEmpty
                            ? ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: att.length,
                                itemBuilder: (context, index) {
                                  return Row(children: [
                                    Flexible(
                                      child: Text(
                                        att[index].trim() + ":",
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(color: lightBlack2),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 5.0),
                                      child: Text(
                                        val[index],
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(color: lightBlack),
                                      ),
                                    )
                                  ]);
                                })
                            : Container(),
                        Row(
                          children: [
                            Text(
                              getTranslated(context, "QUANTITY_LBL")! + ":",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(color: lightBlack2),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 5.0),
                              child: Text(
                                orderItem.qty!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(color: lightBlack),
                              ),
                            )
                          ],
                        ),
                        Text(
                          CUR_CURRENCY + " " + orderItem.price!,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: primary),
                        ),
//==============================================================================
//============================ Status of Order =================================

                        // orderItem.status != DELIVERD
                        //     ? Padding(
                        //         padding:
                        //             const EdgeInsets.symmetric(vertical: 10.0),
                        //         child: Row(
                        //           children: [
                        //             Expanded(
                        //               child: Padding(
                        //                 padding:
                        //                     const EdgeInsets.only(right: 8.0),
                        //                 child: DropdownButtonFormField(
                        //                   dropdownColor: white,
                        //                   isDense: true,
                        //                   iconEnabledColor: primary,
                        //                   hint: Text(
                        //                     getTranslated(
                        //                         context, "UpdateStatus")!,
                        //                     style: Theme.of(this.context)
                        //                         .textTheme
                        //                         .subtitle2!
                        //                         .copyWith(
                        //                             color: primary,
                        //                             fontWeight:
                        //                                 FontWeight.bold),
                        //                   ),
                        //                   decoration: InputDecoration(
                        //                     filled: true,
                        //                     isDense: true,
                        //                     fillColor: white,
                        //                     contentPadding:
                        //                         EdgeInsets.symmetric(
                        //                             vertical: 10,
                        //                             horizontal: 10),
                        //                     enabledBorder: OutlineInputBorder(
                        //                       borderSide:
                        //                           BorderSide(color: primary),
                        //                     ),
                        //                   ),
                        //                   value: orderItem.status,
                        //                   onChanged: (dynamic newValue) {
                        //                     setState(
                        //                       () {
                        //                         orderItem.curSelected =
                        //                             newValue;
                        //                         updateOrder(
                        //                           orderItem.curSelected,
                        //                           updateOrderItemApi,
                        //                           model.id,
                        //                           true,
                        //                           i,
                        //                         );
                        //                       },
                        //                     );
                        //                   },
                        //                   items: statusList.map(
                        //                     (String st) {
                        //                       return DropdownMenuItem<String>(
                        //                         value: st,
                        //                         child: st == "shipped"
                        //                             ? Text(
                        //                                 "Picked Up",
                        //                                 style: Theme.of(
                        //                                         this.context)
                        //                                     .textTheme
                        //                                     .subtitle2!
                        //                                     .copyWith(
                        //                                         color: primary,
                        //                                         fontWeight:
                        //                                             FontWeight
                        //                                                 .bold),
                        //                               )
                        //                             : st == "processed"
                        //                                 ? Text(
                        //                                     "Preparing",
                        //                                     style: Theme.of(this
                        //                                             .context)
                        //                                         .textTheme
                        //                                         .subtitle2!
                        //                                         .copyWith(
                        //                                             color:
                        //                                                 primary,
                        //                                             fontWeight:
                        //                                                 FontWeight
                        //                                                     .bold),
                        //                                   )
                        //                                 : Text(
                        //                                     capitalize(st),
                        //                                     style: Theme.of(this
                        //                                             .context)
                        //                                         .textTheme
                        //                                         .subtitle2!
                        //                                         .copyWith(
                        //                                             color:
                        //                                                 primary,
                        //                                             fontWeight:
                        //                                                 FontWeight
                        //                                                     .bold),
                        //                                   ),
                        //                       );
                        //                     },
                        //                   ).toList(),
                        //                 ),
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //       )
                        //     : Text(
                        //         "DELIVERED",
                        //         style: TextStyle(color: primary),
                        //       ),
//==============================================================================
//============================ Select Delivery Boy =============================

                        delPermission == '1' && orderItem.status != DELIVERD
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: InkWell(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: primary,
                                              ),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(5),
                                              ),
                                            ),
                                            padding: EdgeInsets.all(10),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    index1 != -1 &&
                                                            orderItem
                                                                    .delivery_boy_name !=
                                                                ""
                                                        ? orderItem
                                                            .delivery_boy_name!
                                                        : "Select Rider",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        Theme.of(this.context)
                                                            .textTheme
                                                            .subtitle2!
                                                            .copyWith(
                                                              color: primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  color: primary,
                                                )
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            delboyDialog(orderItem.status!, i);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                )
              ],
            ),
            // orderItem.addonList == null ||
            //         orderItem.addonList!.length == 0 ||
            //         orderItem.addonList![0].name == null ||
            //         orderItem.addonList![0].name == ""
            //     ? SizedBox.shrink()
            //     : Container(
            //         child: ListView.builder(
            //             shrinkWrap: true,
            //             itemCount: orderItem.addonList!.length,
            //             itemBuilder: (c, i) {
            //               return ListTile(
            //                 title: Text("${orderItem.addonList![i].name}"),
            //                 subtitle: Column(
            //                   crossAxisAlignment: CrossAxisAlignment.start,
            //                   children: [
            //                     Text(
            //                         "Price: \u{20B9}${orderItem.addonList![i].price}"),
            //                     Text(
            //                         "Total Price: \u{20B9}${orderItem.addonList![i].totalAmount}")
            //                   ],
            //                 ),
            //                 trailing: Text(
            //                     "Qty: ${orderItem.addonList![i].quantity}"),
            //                 leading: Container(
            //                   height: 45,
            //                   width: 45,
            //                   child: ClipRRect(
            //                       borderRadius: BorderRadius.circular(10),
            //                       child: Image.network(
            //                         "${orderItem.addonList![i].image}",
            //                         fit: BoxFit.cover,
            //                       )),
            //                 ),
            //               );
            //             }),
            //       )
          ],
        ),
      ),
    );
  }

  Future<void> updateOrder(
      String? status, Uri api, String? id, bool item, int index) async {
    print("vvvvvvvvvvv ${tempList[0].itemList![index].id}");

    List<String> idList = [];

    idList.clear();
    for (var i = 0; i < tempList[0].itemList!.length; i++) {
      print("okokoko ${tempList[0].itemList![i].id}");
      idList.add(tempList[0].itemList![i].id.toString());
    }

    String finalIds = idList.join(",");
    print("item id is here $finalIds");

    _isNetworkAvail = await isNetworkAvailable();
    if (true) {
      if (_isNetworkAvail) {
        try {
          var parameter = {
            STATUS: status == "processed" ? "food prepared": status,
          };
          if (item) {
            parameter[ORDERITEMID] = finalIds;
          }
          if (selectedDelBoy != null)
            parameter[DEL_BOY_ID] = searchList[selectedDelBoy!].id;
            print("parameter and api " + parameter.toString() + "$updateOrderItemApi");
          apiBaseHelper.postAPICall(updateOrderItemApi, parameter).then(
            (getdata) async {
              bool error = getdata["error"];
              String msg = getdata["message"];
              setSnackbar(msg);
              print("msg : $msg");
              if (!error) {
                if (item) tempList[0].itemList![index].status = status;
                else tempList[0].itemList![0].activeStatus = status;
                if (selectedDelBoy != null)
                  tempList[0].itemList![0].deliveryBoyId = searchList[selectedDelBoy!].id;
                getOrderDetail();
              } else {
                getOrderDetail();
              }
            },
            onError: (error) {
              setSnackbar(error.toString());
            },
          );
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, "somethingMSg")!);
        }
      } else {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    } else {
      setSnackbar('You have not authorized permission for update order!!');
    }
  }

  _launchCaller() async {
    var url = "tel:${tempList[0].itemList![0].deliveryBoyMobile}";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: black),
      ),
      backgroundColor: white,
      elevation: 1.0,
    ));
  }

  bankProof(Order_Model model) {
    return Card(
      elevation: 0,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: model.attachList!.length, //original file ma joe levu
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  child: Text(
                    getTranslated(context, "Attachment")! +
                        " " +
                        (i + 1).toString(),
                    style: TextStyle(
                        decoration: TextDecoration.underline, color: primary),
                  ),
                  onTap: () {
                    _launchURL(model.attachList![i].attachment!);
                  },
                ),
                InkWell(
                  child: Icon(
                    Icons.delete,
                    color: fontColor,
                  ),
                  onTap: () {
                    // deleteBankProof(i, model);
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _launchURL(String _url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';
}
