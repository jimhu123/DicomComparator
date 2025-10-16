DicomComparator is a Perl script to check if two DICOM files are identical or DICOM files under two folders are identical and then save the differences to a file or show the differences to the standard output device.
DicomComparator uses the DicomPack perl package (https://metacpan.org/dist/DicomPack) to process DICOM files.
In addition to the source codes of DicomComparator, an executable version for Windows compiled by Strawberry Perl is also provided here.

Usage:

perl DicomComparator.pl 1stDicomFileOrFolderPath 2stDicomFileOrFolderPath DicomDiffFilePath IgnorePrivateTag

where, both 1stDicomFileOrFolderPath and 2stDicomFileOrFolderPath can be dicom files or folders containing a series of dicom files; DicomDiffFilePath: a file used to store differences between dicom files. If DicomDiff is "", the difference will printed out to the standard output (e.g., screen); if IgnorePrivateTag=1, private tags will be ignored. 

For example,

1. compare two dicom files (difference will be printed out, private tages will be compared):

perl.exe DicomComparator.pl C:\DICOM\pre-upgrade\RP.1.2.34567.dcm C:\DICOM\post-upgrade\988671\RP.1.2.3456789.dcm "" 0

2. compare two dicom folders (difference will be saved to a file, diff.txt, private tags will be ignored):

perl.exe DicomComparator.pl \\\\radonc-fs1\DICOM\pre-upgrade\pt1 \\\\radonc-fs1\DICOM\post-upgrade\pt1 diff.txt 1

Please note: the script uses file name for pairing dicom files under different folders.
