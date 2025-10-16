use strict;
use warnings;
use DicomPack::IO::DicomReader;
use DicomPack::DB::DicomTagDict qw/getTagDesc getTagID/;
use DicomPack::IO::CommonUtil qw/_toString/;

sub compare_fieldpair
{
	my ($dcmField1, $dcmField2, $depth, $tagID, $ignorePrivateTag) = @_;
	
	my @ignoredDicomTagList = ('0002,0000', '0002,0013', '0008,0012', '0008,0013', '0008,0052', '0008,0054');
	#my @ignoredDicomTagList = ();

	my $indent = " " x (4*$depth);
	if(ref($dcmField1) eq "HASH")
	{
		my %uniques;
		my @tagList1 = sort keys %$dcmField1;
		my @tagList2 = sort keys %$dcmField2;
		@uniques{@tagList1} = @tagList1 x (1);
		@uniques{@tagList2} = @tagList2 x (1);

		my @dcmTagList_t = sort keys %uniques;
		
		
		my $result = "";
		foreach my $field_t (@dcmTagList_t)
		{
			my $desc = getTagDesc($field_t);
			
			if($ignorePrivateTag == 1)
			{
				next if(hex(substr($field_t, 3, 1)) % 2 == 1);
			}
			if(hex(substr($field_t, 3, 1)) % 2 == 0 and $desc eq "Private")
			{
				$desc = "No Description";
			}
			next if (grep { /$field_t/ } @ignoredDicomTagList);
			
			my $return = "";
			if((grep { /$field_t/ } @tagList1) and (grep { /$field_t/ } @tagList2))
			{
				$return = compare_fieldpair($dcmField1->{$field_t}, $dcmField2->{$field_t}, $depth+1, $field_t, $ignorePrivateTag);
			}
			else
			{
				if(not (grep { /$field_t/ } @tagList1))
				{
					$return = $indent." " x (4)."missing in (1)\n";
				}
				if(not (grep { /$field_t/ } @tagList2))
				{
					$return = $indent." " x (4)."missing in (2)\n";
				}
			}
			#my $return = compare_fieldpair($dcmField1->{$field_t}, $dcmField2->{$field_t}, $depth+1, $field_t, $ignorePrivateTag);
			if($return ne '')
			{
				$result = $result.$indent."$field_t"." [".$desc."]"."->\n";
				$result = $result.$return;
			}
		}
		return $result;
	}
	elsif(ref($dcmField1) eq "ARRAY")
	{
		my $result = "";
		my $itemNum1 = scalar @$dcmField1;
		my $itemNum2 = scalar @$dcmField2;
		
		if($itemNum1 != $itemNum2)
		{
			$result = $indent."Different Item Numbers: ".$itemNum1."<-->".$itemNum2."\n";
		}
		else
		{
			for(my $index=0; $index < scalar @$dcmField1; $index++)
			{
				my $return = compare_fieldpair($dcmField1->[$index], $dcmField2->[$index], $depth+1, '', $ignorePrivateTag);
				if($return ne '')
				{
					$result = $result.$indent."$index->\n";
					$result = $result.$return;
				}
			}
		}
		return $result;
	}
	else
	{
		my $str1 = _toString($dcmField1, 1, 1, $indent);
		my $str2 = "";
		if(defined($dcmField2))
		{
			$str2 = _toString($dcmField2, 1, 1, $indent);
		}
		my $result = "";
		if($str1 ne $str2)
		{
			if($str1 =~ /[^[:print:]]/g)
			{
				$str1 = "NON-PRINTABLE";
			}
			if($str2 =~ /[^[:print:]]/g)
			{
				$str2 = "non-printable";
			}
			
			if(length($str1)>=3)
			{
				$str1 = substr($str1, 3);
			}
			if(length($str2)>=3)
			{
				$str2 = substr($str2, 3);
			}

			$result = $indent.$str1."<-->".$str2."\n";
		}
		return $result;
	}
}

sub compare_dicompair
{
	my ($dcmFile1, $dcmFile2, $ignorePrivateTag) = @_;
	
	$ignorePrivateTag = 0 if not defined($ignorePrivateTag);
	
	my $dcmReader1 = DicomPack::IO::DicomReader->new($dcmFile1);
	my $dcmReader2 = DicomPack::IO::DicomReader->new($dcmFile2);
	my $dcmField1 = $dcmReader1->getDicomField();
	my $dcmField2 = $dcmReader2->getDicomField();

	my $result = compare_fieldpair($dcmField1, $dcmField2, 0, '', $ignorePrivateTag);

	return $result;
	#print $dcmReader1->getValue("PatientName"), $dcmReader2->getValue("PatientName");
}

sub compare_dicomfolderpair
{
	my ($dcmFolder1, $dcmFolder2, $ignorePrivateTag) = @_;
	if($dcmFolder1 =~ /\/$/)
	{
		chop($dcmFolder1);
	}
	if($dcmFolder2 =~ /\/$/)
	{
		chop($dcmFolder2);
	}

	opendir(my $dh1, $dcmFolder1) or die "Error: cannot open directory $dcmFolder1: $!";
	opendir(my $dh2, $dcmFolder2) or die "Error: cannot open directory $dcmFolder2: $!";
    my @dcmFileNameList1 = readdir($dh1);
	my @dcmFileNameList2 = readdir($dh2);
	close($dh1);
	close($dh2);
	
	my %uniques;
	@uniques{@dcmFileNameList1} = @dcmFileNameList1 x (1);
	@uniques{@dcmFileNameList2} = @dcmFileNameList2 x (1);
	
	my @dcmFileNameList = sort keys %uniques;
	my $diffResultTotal = "";

	my $fileCnt = 0;
	foreach my $dcmFileName (@dcmFileNameList)
	{
		next if not $dcmFileName =~ /\.dcm$/;
		my $dcmFile1 = $dcmFolder1."/".$dcmFileName;
		my $dcmFile2 = $dcmFolder2."/".$dcmFileName;

		$fileCnt++;
		$diffResultTotal = $diffResultTotal.">>>>>> ".$fileCnt.": ".$dcmFileName."\n";
		if(-f $dcmFile1 and -f $dcmFile2)
		{
			my $diffResult_t = compare_dicompair($dcmFile1, $dcmFile2, $ignorePrivateTag);
			$diffResultTotal = $diffResultTotal.$dcmFile1."\n".$dcmFile2."\n".$diffResult_t;
		}
		else
		{
			for my $tt ($dcmFile1, $dcmFile2)
			{
				if(-f $tt)
				{
					$diffResultTotal = $diffResultTotal.$tt."\n";
				}
				else
				{
					$diffResultTotal = $diffResultTotal.$tt.": non-existent\n";
				}
			}
		}
		$diffResultTotal = $diffResultTotal."\n\n\n";
	}
	return $diffResultTotal;
}

my ($dcmFileOrFolder1, $dcmFileOrFolder2, $diffFile, $ignorePrivateTag) = @ARGV;

$dcmFileOrFolder1 =~ s/\\/\//g;
$dcmFileOrFolder2 =~ s/\\/\//g;

my $diffResultTotal = "";
if( -f $dcmFileOrFolder1 and -f $dcmFileOrFolder1)
{
	my $diffResult = compare_dicompair($dcmFileOrFolder1, $dcmFileOrFolder2, $ignorePrivateTag);
	$diffResultTotal = $diffResultTotal.$dcmFileOrFolder1."\n".$dcmFileOrFolder2."\n".$diffResult;
}

if( -d $dcmFileOrFolder1 and -d $dcmFileOrFolder1)
{
	$diffResultTotal = compare_dicomfolderpair($dcmFileOrFolder1, $dcmFileOrFolder2, $ignorePrivateTag);
}

if(defined($diffFile) and  $diffFile ne '')
{
	open(my $fh, ">", $diffFile) or die "Error: cannot open file ".$diffFile." for writing: $!";
	print $fh $diffResultTotal;
	close($fh);
}
else
{
	print $diffResultTotal, "\n";
}
