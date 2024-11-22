import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:moonie/image.dart';
import 'package:provider/provider.dart';

class CroppableImageController extends ChangeNotifier {
  String? _imagePath;
  bool _isCropping = false;

  Function? onImagePicked;

  CroppableImageController({String? initialImage, this.onImagePicked}) {
    _imagePath = initialImage;
  }

  bool get isCropping => _isCropping;
  set isCropping(bool value) {
    _isCropping = value;
    notifyListeners();
  }

  String? get imagePath => _imagePath;
  set imagePath(String? path) {
    _imagePath = path;
    if (onImagePicked != null) {
      onImagePicked!(imagePath);
    }
    notifyListeners();
  }
}

// Allows uploading and cropping images to app
class CroppableImage extends StatefulWidget {
  final double height;
  final CroppableImageController controller;
  const CroppableImage(
      {super.key, required this.height, required this.controller});

  @override
  State<CroppableImage> createState() => _CroppableImageState();
}

class _CroppableImageState extends State<CroppableImage> {
  CropController cropController = CropController();
  late final CroppableImageController controller = widget.controller;

  ImageProvider? imageProvider;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    if (controller.imagePath != null) {
      final f = File(controller.imagePath!);
      if (f.existsSync()) {
        setImageProvider(f);
      }
    }
  }

  void setImageProvider(File f) async {
    imageProvider = FileImage(f);
    imageBytes = await f.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          SizedBox(
            height: widget.height * 0.8,
            child: ChangeNotifierProvider.value(
              value: controller,
              child: Consumer<CroppableImageController>(
                  builder: (context, controller, _) {
                if (controller.isCropping) {
                  return (imageProvider != null)
                      ? Crop(
                          image: imageBytes!,
                          controller: cropController,
                          onCropped: (result) async {
                            final res = await writeImageToImagesDir(
                                controller.imagePath!, result);
                            setState(() {
                              imageProvider = FileImage(res);
                              controller.imagePath = res.path;
                            });
                          },
                        )
                      : Container();
                } else {
                  return (imageProvider != null)
                      ? Image(image: imageProvider!)
                      : Container();
                }
              }),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              ActionChip(
                label: const Text("Upload Image"),
                onPressed: () async {
                  final files = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );
                  if (files != null) {
                    final file = files.files.single;
                    final copiedFile = await copyImageToImagesDir(file.path!);
                    setState(() {
                      controller.imagePath = copiedFile.path;
                      setImageProvider(copiedFile);
                      controller.onImagePicked!(controller.imagePath);
                    });
                  }
                },
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                icon: const Icon(Icons.crop),
                visualDensity: VisualDensity.compact,
                onPressed: (imageProvider != null)
                    ? () {
                        setState(() {
                          if (controller.isCropping) {
                            cropController.crop();
                          }
                          controller.isCropping = !controller.isCropping;
                        });
                      }
                    : null,
              )
            ],
          ),
        ],
      ),
    );
  }
}
