String formatDateTime1(DateTime dateTime) {
  return '${dateTime.year % 100}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String imageMimeFromFilePath(String filePath) {
  return {
        'png': 'image/png',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'gif': 'image/gif',
        'webp': 'image/webp',
        'bmp': 'image/bmp',
        'tiff': 'image/tiff',
      }[filePath.split('.').last.toLowerCase()] ??
      'image/unknown';
}
