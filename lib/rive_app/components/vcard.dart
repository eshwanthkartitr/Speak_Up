import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_samples/rive_app/models/courses.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VCard extends StatefulWidget {
  const VCard({Key? key, required this.course}) : super(key: key);

  final CourseModel course;

  @override
  State<VCard> createState() => _VCardState();
}

class _VCardState extends State<VCard> {
  final avatars = [4, 5, 6];

  @override
  void initState() {
    avatars.shuffle();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260, maxHeight: 310),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [widget.course.color, widget.course.color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
            color: widget.course.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: widget.course.color.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  widget.course.title,
                  style: const TextStyle(
                      fontSize: 24, fontFamily: "Poppins", color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.course.subtitle!,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: false,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                widget.course.caption.toUpperCase(),
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                children: avatars
                    .mapIndexed(
                      (index, number) => Transform.translate(
                        offset: Offset(index * -20, 0),
                        child: ClipRRect(
                          key: Key(index.toString()),
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                              "assets/rive_app/images/avatars/avatar_$number.jpg",
                              width: 44,
                              height: 44),
                        ),
                      ),
                    )
                    .toList(),
              )
            ],
          ),
          // Replace Image.asset with FontAwesome icon
          Positioned(
            right: -10, 
            top: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: FaIcon(
                  widget.course.getIcon(),
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
