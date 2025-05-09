import 'package:flutter/material.dart';

class Add extends StatefulWidget {
  const Add({super.key});

  @override
  State<Add> createState() => _AddState();
}

class _AddState extends State<Add> {
 @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 13, 207, 42),
            borderRadius: BorderRadius.circular(7),
            
            
            
          ),
          child: Row(
            children: [
              
              //Image.asset("https://cdn-icons-png.flaticon.com/512/992/992651.png", height: 100, color: Colors.amber),
              IconButton(onPressed: (){}, icon: Icon(Icons.add), ),
             
            ],
          ),
        )
      ],
      
    );
  }
}