import 'package:flutter/material.dart';

  Image logoWidget(String imageName) {
    return Image.asset(
      imageName,
      fit: BoxFit.fitWidth,
      width: 240,
      height: 240,
      color: const Color.fromARGB(255, 0, 1, 4),
    );
  }


TextField reusableTextField(String text, IconData icon, bool isPasswordType,  
    TextEditingController controller) {  
  return TextField(  
    controller: controller,  
    obscureText: isPasswordType,  
    enableSuggestions: !isPasswordType,  
    autocorrect: !isPasswordType,  
    cursorColor: Colors.white,  
    style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.9)),  
    decoration: InputDecoration(  
      prefixIcon: Icon(  
        icon,  
        color: Color.fromRGBO(255, 255, 255, 0.7),  
      ), // Icon  
      labelText: text,  
      labelStyle: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.9)),  
      filled: true,  
      floatingLabelBehavior: FloatingLabelBehavior.never,  
      fillColor: Color.fromRGBO(255, 255, 255, 0.3),  
      border: OutlineInputBorder(  
        borderRadius: BorderRadius.circular(30.0),  
        borderSide: const BorderSide(width: 0, style: BorderStyle.none)), // OutlineInputBorder  
    ), // InputDecoration  
    keyboardType: isPasswordType  
        ? TextInputType.visiblePassword  
        : TextInputType.emailAddress,  
  ); // TextField  
}

Container signInSignUpButton(BuildContext context, bool isLogin, Function onTap) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(9)),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      style: ElevatedButton.styleFrom( // Alternative for MaterialStateProperty
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        isLogin ? 'LOG IN' : 'SIGN UP',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
  );
}



