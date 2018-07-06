#!/bin/sh
export LD_LIBRARY_PATH=/home/mcc262/Desktop/Un/executables 
org_path=/home/mcc262/Desktop/Un/video2min
des_path=/home/mcc262/Desktop/Un/video5second

cutlong=5 #125
minFrames=50 #2250

outDir=/home/mcc262/Desktop/Un/video5second/out
logDir=/home/mcc262/Desktop/Un/video5second/log
RecDir=/home/mcc262/Desktop/Un/video5second/rec
VMAFDir=/home/mcc262/Desktop/Un/vmaf_tool
bin_postfix=bin

for foldername in $(ls ${org_path})
do
	desFolder=${des_path}/${foldername}
	if [ ! -d ${desFolder} ] 
	then
		mkdir -p ${desFolder} 	
	fi
	if [ ! -d ${outDir} ] 
	then
		mkdir -p ${outDir} 	
	fi	
	if [ ! -d ${logDir} ] 
	then
		mkdir -p ${logDir} 	
	fi	
	if [ ! -d ${RecDir} ] 
	then
		mkdir -p ${RecDir} 	
	fi	
	IPeriod=125
	framerate=25000
	framenum=9999
	pass=0
	rcmode=3
	bin_postfix=bin
	dataFile=HW265_test_result.csv
	featureFile=AvgFeatures.csv	
	cd ${org_path}/${foldername}
	for filename in $(ls ${org_path}/${foldername}) 
	do	
		sequence=`echo $filename | cut -d . -f 1`
		fileInfo=`ffprobe -show_streams ${org_path}/${foldername}/${filename}`
		flag=0
		for line in $fileInfo
		do
		  key=`echo $line | cut -d = -f 1`
		  value=`echo $line | cut -d = -f 2`
		  if [ $key == 'codec_type' -a $value == 'video' ]
		  then
			flag=1
			continue
		  fi
		  if [ $flag == 1 -a $key == 'duration' ]
		  then
			frames=${value%.*}
			rate=25
			let frames=$rate*$frames
			echo frames=
			echo $frames		  
			break
		  fi
		done
		echo ${frames}
		if [ $frames -ge $minFrames ]
		then
			ss=0
			starttime=0
			endtime=0
			ffmpeg -y -i ${org_path}/${foldername}/${sequence}.ts ${des_path}/${foldername}/${sequence}.yuv 
			cd ${des_path} 
			#frames=15 #test 15 frames, need del
			while [ $(($ss+$cutlong)) -le $frames ]
			do
				let starttime=$ss
				let endtime=$ss+$cutlong
				#1080p		
				ffmpeg -y -r 1 -s 1920x1080 -i ${des_path}/${foldername}/${sequence}.yuv -ss $starttime -t $cutlong ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}.yuv
				width=1920
				height=1080
				for quality in 3
				do
					filename2=${sequence}_${starttime}_${endtime}.yuv
					sequence2=${filename2%.*}
					for crf in `seq 10 42` #10-42
					do
						./H265EncoderD -c encoder.cfg -quality_level $quality -rc $rcmode -crf $crf -pass $pass -fr $framerate -frames $framenum -w $width -h $height -keyInt $IPeriod -b ${outDir}/${sequence2}_HW_Q${quality}_CRF${crf}.${bin_postfix} -i ${des_path}/${foldername}/${sequence2}.yuv 1>${logDir}/encod_${sequence2}_HW_Q${quality}_CRF${crf}.txt
						#rec
						ffmpeg -i ${outDir}/${sequence2}_HW_Q${quality}_CRF${crf}.${bin_postfix} ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv		    
						vmaf_info=`./vmafossexec yuv420p $width $height ${des_path}/${foldername}/${sequence2}.yuv ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv vmaf_v0.6.1.pkl --tv-model`
						vmaf=`echo $vmaf_info | cut -d = -f 2`
						echo $sequence2,$vmaf >>tail.csv
						rm ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv
					done		
				done
				#720p
				ffmpeg -s 1920x1080 -pix_fmt yuv420p -i ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}.yuv -f rawvideo -s 1280x720 ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}_1280x720.yuv
				width=1280
				height=720
				for quality in 3
				do
					filename2=${sequence}_${starttime}_${endtime}_1280x720.yuv
					sequence2=${filename2%.*}
					for crf in `seq 10 42` #10-42
					do
						./H265EncoderD -c encoder.cfg -quality_level $quality -rc $rcmode -crf $crf -pass $pass -fr $framerate -frames $framenum -w $width -h $height -keyInt $IPeriod -b ${outDir}/${sequence2}_HW_Q${quality}_CRF${crf}.${bin_postfix} -i ${des_path}/${foldername}/${sequence2}.yuv 1>${logDir}/encod_${sequence2}_HW_Q${quality}_CRF${crf}.txt
						#rec
						ffmpeg -i ${outDir}/${sequence2}_HW_Q${quality}_CRF${crf}.${bin_postfix} ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv		    
						vmaf_info=`./vmafossexec yuv420p $width $height ${des_path}/${foldername}/${sequence2}.yuv ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv vmaf_v0.6.1.pkl --tv-model`
						vmaf=`echo $vmaf_info | cut -d = -f 2`
						echo $sequence2,$vmaf >>tail.csv
						rm ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv
					done		
				done
				#480p
				ffmpeg -s 1920x1080 -pix_fmt yuv420p -i ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}.yuv -f rawvideo -s 854x480 ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}_854x480.yuv
				width=854
				height=480
				for quality in 3
				do
					filename2=${sequence}_${starttime}_${endtime}_854x480.yuv
					sequence2=${filename2%.*}
					for crf in `seq 10 42` #10-42
					do
						./H265EncoderD -c encoder.cfg -quality_level $quality -rc $rcmode -crf $crf -pass $pass -fr $framerate -frames $framenum -w $width -h $height -keyInt $IPeriod -b ${outDir}/${sequence2}_HW_Q${quality}_CRF${crf}.${bin_postfix} -i ${des_path}/${foldername}/${sequence2}.yuv 1>${logDir}/encod_${sequence2}_HW_Q${quality}_CRF${crf}.txt
						#rec
						ffmpeg -i ${outDir}/${sequence2}_HW_Q${quality}_CRF${crf}.${bin_postfix} ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv		    
						vmaf_info=`./vmafossexec yuv420p $width $height ${des_path}/${foldername}/${sequence2}.yuv ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv vmaf_v0.6.1.pkl --tv-model`
						vmaf=`echo $vmaf_info | cut -d = -f 2`
						echo $sequence2,$vmaf >>tail.csv
						rm ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv
					done		
				done			
				#270p
				ffmpeg -s 1920x1080 -pix_fmt yuv420p -i ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}.yuv -f rawvideo -s 480x270 ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}_480x270.yuv
				width=480
				height=270
				for quality in 3
				do
					filename2=${sequence}_${starttime}_${endtime}_480x270.yuv
					sequence2=${filename2%.*}
					for crf in `seq 10 42` #10-42
					do
						./H265EncoderD -c encoder.cfg -quality_level $quality -rc $rcmode -crf $crf -pass $pass -fr $framerate -frames $framenum -w $width -h $height -keyInt $IPeriod -b ${outDir}/${sequence2}_HW_Q${quality}_CRF${crf}.${bin_postfix} -i ${des_path}/${foldername}/${sequence2}.yuv 1>${logDir}/encod_${sequence2}_HW_Q${quality}_CRF${crf}.txt
						#rec
						ffmpeg -i ${outDir}/${sequence2}_HW_Q${quality}_CRF${crf}.${bin_postfix} ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv		    
						vmaf_info=`./vmafossexec yuv420p $width $height ${des_path}/${foldername}/${sequence2}.yuv ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv vmaf_v0.6.1.pkl --tv-model`
						vmaf=`echo $vmaf_info | cut -d = -f 2`
						echo $sequence2,$vmaf >>tail.csv
						rm ${RecDir}/${sequence2}_HW_Q${quality}_CRF${crf}_Rec.yuv
					done		
				done				
				let ss+=$cutlong
				echo ${starttime} ${endtime}
				rm ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}.yuv
				rm ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}_1280x720.yuv
				rm ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}_854x480.yuv
				rm ${des_path}/${foldername}/${sequence}_${starttime}_${endtime}_480x270.yuv
			done			
            rm ${des_path}/${foldername}/${sequence}.yuv
		fi

	done

done
