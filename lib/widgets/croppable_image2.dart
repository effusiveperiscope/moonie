import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:moonie/image.dart';
import 'package:croppy/croppy.dart' hide CroppableImageController;
import 'package:image_compression_flutter/image_compression_flutter.dart' as ic;

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

// Testing croppy b/c crop_your_image output file size is too large
// Nope -- we probably need to re-encode the image somehow while in memory
class CroppableImage2 extends StatefulWidget {
  final double height;
  final int aspectWidth, aspectHeight;
  final CroppableImageController controller;
  const CroppableImage2(
      {super.key,
      required this.height,
      this.aspectWidth = 1,
      this.aspectHeight = 1,
      required this.controller});

  @override
  State<CroppableImage2> createState() => _CroppableImage2State();
}

// Rather than cropping the image separately, this time we'll just display a crop prompt
// When the image is first uploaded.
class _CroppableImage2State extends State<CroppableImage2> {
  ImageProvider? imageProvider;

  @override
  void initState() {
    super.initState();
    if (widget.controller.imagePath != null) {
      final f = File(widget.controller.imagePath!);
      if (f.existsSync()) {
        imageProvider = FileImage(f);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: widget.height,
        child: Column(
          children: [
            SizedBox(
                height: widget.height * 0.8,
                child: (imageProvider != null)
                    ? Image(image: imageProvider!)
                    : Container()),
            const SizedBox(height: 4.0),
            ActionChip(
              label: const Text('Upload Image'),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result != null) {
                  final fp = result.files.single.path!;
                  final f = File(fp);
                  // Display crop prompt
                  final res = await showMaterialImageCropper(context,
                      imageProvider: FileImage(f),
                      allowedAspectRatios: [
                        CropAspectRatio(
                            width: widget.aspectWidth,
                            height: widget.aspectHeight),
                      ]);
                  if (res == null) {
                    return;
                  }
                  final data = await res.uiImage.toByteData(
                    format: ImageByteFormat.png,
                  );
                  final dataBytes = data!.buffer.asUint8List();

                  // Why does it need both path and rawBytes???
                  final input = ic.ImageFile(filePath: fp, rawBytes: dataBytes);
                  const config = ic.Configuration(
                    outputType: ic.ImageOutputType.png,
                    quality: 80,
                  );
                  final params =
                      ic.ImageFileConfiguration(input: input, config: config);
                  final output = await ic.compressor.compress(params);

                  final newFile =
                      await writeImageToImagesDir(fp, output.rawBytes, 'png');

                  setState(() {
                    imageProvider = FileImage(newFile);
                  });
                  widget.controller.imagePath = newFile.path;
                }
              },
            )
          ],
        ));
  }
}
