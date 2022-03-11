#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ File (label = "Model file", style = "file", required=false) model
#@ String (label = "Channel", value="VEC") channel
#@ String (choices={"TestImagesSelection", "WekaProcessing"}, style="radioButtonHorizontal") processing

// -----------------------------------------------------------
// GLOBAL VARIABLES
// -----------------------------------------------------------
var VERSION = 1.0;
/*
VERSION 1.0: first release. Full configurable weka processing.
             Log window used to check when the model has been loaded
             and read the class names within the model.
VERSION 0.2: weka processing implemented. Missing output split.
VERSION 0.1: beta release for Lorenzo. Only sub-images selection implemented.
*/
var suffix = ".tif";
// -----------------------------------------------------------
// MACRO EXECUTION
// -----------------------------------------------------------
if (isOpen("Log")) 
{
     selectWindow("Log");
     run("Close" );
}
if (lengthOf(channel) == 0)
{
    // Check a name has been chosen for the channel if
    // no name has been selected all images will be processed
	channel = "NA";
}
WriteToLog("create");

// Verify that images are available in the input folder
var availableImages = newArray;
availableImages = ListAvailableImages(input, channel, availableImages);
WriteToLog("Available images: " + availableImages.length);
if (availableImages.length == 0)
{
	ErrorDialog("No available images for the selected channel. Quitting.");	
}

// Sub-images selection
if (processing == "TestImagesSelection")
{
    WriteToLog("\nSub-images selection:");
    subImagesInfo = newArray;
	imageIndexes = newArray;
	// Get sourceImgNr, subImagesPerSource, subImgWidth, subImgHeigth
	subImagesInfo = SelectSubImagesDialog(availableImages.length, subImagesInfo);
    // Get random indexes for the input images
    imageIndexes = SelectRandomIndexes(subImagesInfo[0], availableImages.length-1, imageIndexes); 
    // Create sub-images and save them
	outfolder = output + File.separator + "trainerset";
	outputFilename = outfolder + File.separator + "tester";
	File.makeDirectory(outfolder);    
    WriteToLog("\nSub-images selection:");
    WriteToLog("output sub-folder: " + outfolder);
    outputCounter = 0;
    for(i=0; i<imageIndexes.length; i++)
    {
    	inputFilename = input + File.separator + availableImages[i];
    	for(j=0; j<subImagesInfo[1]; j++)
    	{
    	    outputCounter = ExtractTesterSubImgs(inputFilename, outputFilename, outputCounter,
    	    								     subImagesInfo[1], subImagesInfo[2], subImagesInfo[3]);
    	}    	
    }
    message = "" + outputCounter + " tester images created in " + outfolder; 
    InfoDialog(message);
}

// Weka processing
if (processing == "WekaProcessing")
{
    if (model == 0)
    {
    	ErrorDialog("No model selected! Quitting.");
    }
    WriteToLog("\nWeka processing:");
	outfolder = output + File.separator + "probMap";
	File.makeDirectory(outfolder);
	WriteToLog("output sub-folder: " + outfolder);
	// Open the Segmentator passing the first selected image as input
	inputFilename = input + File.separator + availableImages[0];
	run("Trainable Weka Segmentation", "open=&inputFilename");	
    // Load the model
    InfoDialog("Loading model. This could take some time...\n(timeout=1min)");
    selectWindow("Trainable Weka Segmentation v3.3.1");
	call("trainableSegmentation.Weka_Segmentation.loadClassifier", model);
	waitedSeconds = 0;
	loggedInfo = "";
	// Timeout mechanism and collection of log information
	while (waitedSeconds < 60)
	{
		wait(1000);
		loggedInfo = getInfo("log");
		if (lastIndexOf(loggedInfo, "Loaded") != -1)
		{
			break;
		}
		else if (lastIndexOf(loggedInfo, "Error") != -1)
		{
			WriteToLog("model load failed, quitting");
			ErrorDialog("Model load failed. Quitting");
			exit();
		}
		else
		{
			print("waiting");
		}
		waitedSeconds += 1;
	}
	if (waitedSeconds == 40)
	{
		WriteToLog("model load timed out, quitting");
		ErrorDialog("Model load timed out. Quitting");
		exit();	
	}
	WriteToLog("model loaded");
	// Retrieve name and number of the classes in the model
	var classNames = newArray;
	classNames = GetModelInfo(loggedInfo, classNames);
	// Ask further configuration to the user: out suffix for each class and number of images
	var classSuffixes = newArray(classNames.length);
    procImgNr = SelectWekaConfigurationDialog(availableImages.length, classNames);
    // Apply model and save the probability maps
    InfoDialog("Starting processing.\nCheck progress using the log file in " + output);
    WriteToLog("Starting processing...");
	for (i = 0; i < procImgNr; i++)
	{
		ApplyWekaModel(input, availableImages[i], outfolder);
	}
	close();
	// Post-process probability maps to generate the output images
	WriteToLog("Starting output images generation...");
	for (i = 0; i < procImgNr; i++)
	{
		CreateWekaOutputFiles(outfolder, availableImages[i], classNames, classSuffixes);
	}	
    WriteToLog("Done.");
	message = "" + procImgNr + " images processed. Results in " + outfolder;
    InfoDialog(message);
}


// -----------------------------------------------------------
// -----------------------------------------------------------
// CUSTOM FUNCTIONS TO SUPPORT MACROS EXECUTION
// -----------------------------------------------------------
// -----------------------------------------------------------
// ***********************************************************************
// [FUNCTIONS] SINGLE IMAGE PROCESSING
// ***********************************************************************
function ApplyWekaModel(inpufolder, imagename, outfolder)
{
	WriteToLog(" processing image: " + availableImages[i]);
	selectWindow("Trainable Weka Segmentation v3.3.1");
	call("trainableSegmentation.Weka_Segmentation.applyClassifier", inpufolder , imagename, "showResults=true", "storeResults=false", "probabilityMaps=true", "");
	close();
    outputFilename = outfolder + File.separator + imagename;
	saveAs("Tiff", outputFilename);
	close();
	run("Collect Garbage");
	return outputFilename;
}

function ExtractTesterSubImgs(inputfile, outputfilename, counter, subImgNr, width, heigth)
{
    open(inputfile);
    startCoord = newArray(2);
	for (i = 0; i < subImgNr; i++) 
	{
		startCoord = GetTesterImgStartPosition(width, heigth, startCoord);
		makeRectangle(startCoord[0], startCoord[1], width, heigth);
		run("Copy");
		run("Internal Clipboard");
		saveAs("Tiff", outputfilename + counter);
		close();
		run("Collect Garbage");
		counter += 1;	    	
    }	
	close();
	run("Collect Garbage");

	return counter;
}

// ***********************************************************************
// [FUNCTIONS] CONDITIONAL IMAGES PROCESSING
// ***********************************************************************
function GetModelInfo(logstring, classNames)
{
	WriteToLog("classes loaded in the model:");
	classLoaded = "Read class name: ";
	logLines = split(logstring, "\n\r");
	for (i=0; i<logLines.length; i++)
	{
		if (indexOf(logLines[i], classLoaded) != -1)
		{
			classNames = Array.concat(classNames, substring(logLines[i], lengthOf("Read class name: ")));
			WriteToLog(" " + substring(logLines[i], lengthOf("Read class name: ")));
		}
	}
	if (classNames.length == 0)
	{
		WriteToLog(" no class found, quitting");
		ErrorDialog("no class found in the model. Quitting");
	}
	return classNames;
}

function CreateWekaOutputFiles(folder, filename, classIds, classSuffixes) 
{
	open(folder + File.separator + filename);
	nameonly = File.nameWithoutExtension;
	// Convert stack to images
	run("8-bit");
	run("Stack to Images");
	for(i=0; i<classSuffixes.length; i++)
	{
		selectWindow(classIds[i]);
		// Save image with the right suffix, if required
		if (classSuffixes[i] != "nooutput")
		{
		    saveAs("Tiff", folder + File.separator + nameonly + "_" + classSuffixes[i]);
		}
		close();
	}
	// Delete the input file containing the stack
	File.delete(folder + File.separator + filename);
}

function GetTesterImgStartPosition(width, heigth, coord)
{
	// Assume input images are 1080x1080. We want to leave a margin
	// of at least 50 pixels on each side of the image.
    SIDE_MARGIN = 50;
    SIDE_SIZE = 1080;
	coord[0] = SIDE_MARGIN + round(random * (SIDE_SIZE-width-2*SIDE_MARGIN));
	coord[1] = SIDE_MARGIN + round(random * (SIDE_SIZE-heigth-2*SIDE_MARGIN));
	return coord;
}

function SelectRandomIndexes(selectedNr, maxIndex, outputIndexes)
{
    if (selectedNr == maxIndex+1)
    {
    	// all indexes are selected
    	for (i=0; i<=maxIndex; i++)
    	{
    		outputIndexes = Array.concat(outputIndexes, i);
    	}
    }
    else
    {
	    while (outputIndexes.length < selectedNr)
	    {
		    newIndex = round(random() * maxIndex);
			outputIndexes = UpdateSet(newIndex, outputIndexes);
	    }
    }
    outputIndexes = Array.sort(outputIndexes);
    return outputIndexes;
}

// ****************************************************
// [FUNCTIONS] DIALOGS FOR USER INTERACTION
// ****************************************************
function SelectWekaConfigurationDialog(availableNr, classIds)
{
    // Select number of images, map class names and enable corresponding
    // images to be saved in output
  	html = "<html>"
     +"<h2>Weka output configuration help</h2>"
     +"<body>
     +"When processing the input image, a different output is created for each class in the model.<br>"
     +" <br>"
     +"For each class:<br>"
     +"- check the checkbox to save the corresponding output to file;<br>"
     +"- define the suffix that will be added to the input filename to generate the output filename. <br>"
     +"<b>NOTE:</b> an underscore will be automatically added before the chosen suffix!<br>"
     +" <br>"
     +"Example: input filename: image.tif; 2 classes in the model<br>"
     +"class1 enabled, suffix=CPM; class2 disabled <br>" 
	 +"------> a single will be saved, containing the result for class1, called <b>image_CPM.tif</b><br>"
     +"</body>";
	Dialog.addHelp(html);

	Dialog.create("Configure weka processing");
	message = "Weka model loaded!\n";

	// Number of images to be processed
	message = "Images to process:";
	Dialog.addNumber(message, availableNr);	
	// Map of classes to output suffix
	message = "For each class, enable/disable output and\ndefine filename suffix (no underscore).\n";
	Dialog.addMessage(message);
	defaultClassNames = newArray("CPM", "JPM");
	for (i=0; i<classIds.length; i++)
	{
		Dialog.addCheckbox("Output "+classIds[i], true);
		Dialog.addToSameRow();
		if (i<defaultClassNames.length)
		{
		    Dialog.addString("file suffix", defaultClassNames[i]);
		}
		else 
		{
            Dialog.addString("file suffix", "CLS"+classNr);
		}
	}
	Dialog.show();
	// Number of images
	imagesToProc = round(Dialog.getNumber());
    if (imagesToProc > availableImages.length)
    {
    	imagesToProc = availableImages.length;
    }	
	// Log information to file
	message = "Number of images selected: " + imagesToProc;
	WriteToLog(message);
	// Class suffixes	
	for (i=0; i<classIds.length; i++)
	{
		enableClassOutput = Dialog.getCheckbox();
	    classSuffixes[i] = Dialog.getString();    
	    if (enableClassOutput == false)
	    {
	    	classSuffixes[i] = "nooutput";
	    	WriteToLog(" " +classIds[i]+": no output");
	    }
	    else 
        {
		    WriteToLog(" " +classIds[i]+": output with suffix _" + classSuffixes[i]);
        }
	}
	return imagesToProc;
}

function SelectSubImagesDialog(inputImagesNr, selection)
{
	Dialog.create("Select sub-images");
	message = "Select sub-images of size width x heigth randomly from N input images";
	message += "\n(M from each randomly selected input image, at random positions).";
	message += "\nNumber of input images available: " + inputImagesNr;
	Dialog.addMessage(message);
	Dialog.addNumber("Number of input images used as source (N):", inputImagesNr);
	Dialog.addNumber("Number of sub-images per input image(M):", 1);
	Dialog.addNumber("Sub-images width:", 200);
	Dialog.addNumber("Sub-images heigth:", 200);
	Dialog.show();
	selection = Array.concat(selection, round(Dialog.getNumber()));
	selection = Array.concat(selection, round(Dialog.getNumber()));
	selection = Array.concat(selection, round(Dialog.getNumber()));
	selection = Array.concat(selection, round(Dialog.getNumber()));
	if (selection[0] > inputImagesNr)
	{
		selection[0] = inputImagesNr;
	}
	else
	{
		if (selection[0] == 0)
		{
			selection[0] = 1;
		}
	}
	message = " sourceImgNr = " + selection[0] + "\n";
	message += " subImagesPerSource = " + selection[1] + "\n";
	message += " size " +selection[2]+"x"+selection[3] + "\n";
	WriteToLog(message);
	return selection;
}

function ErrorDialog(message)
{
    WriteToLog("\n");
	WriteToLog(message);
	Dialog.create("Error");
	Dialog.addMessage(message);
	Dialog.show();
	exit();
}

function InfoDialog(message)
{
	Dialog.create("Info");
	Dialog.addMessage(message);
	Dialog.show();
}

// ****************************************************
// [FUNCTIONS] LOGFILE MANAGEMENT AND DEBUG SUPPORT
// ****************************************************
function WriteToLog(logstring)
{
	logfilename = output + File.separator + "WekaProcessing.log";
	if (logstring != "create")
	{
		File.append(logstring, logfilename);
		return;
	}
	// Processing started: create new log file and start logging
	if (File.exists(logfilename))
	{
		File.delete(logfilename);
	}
	logfile = File.open(logfilename);
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	month = month + 1;
	dayOfMonth = dayOfMonth + 1;
	print(logfile, "-----------------------------------------------");
	print(logfile, dayOfMonth+"/"+month+"/"+year+" "+hour+":"+minute+":"+second+"  EC ANALYSIS LOG");
	print(logfile, "-----------------------------------------------");
	print(logfile, "Input folder:  " + input);
	print(logfile, "Output folder: " + output);
	print(logfile, "Weka model:    " + model);
	print(logfile, "Channel:       " + channel);
	print(logfile, "Processing:    " + processing);
	File.close(logfile);	
}

function printArray(myarrayname, myarray, output)
{
	message = myarrayname + ": ";
	if (output)
	{
		message += "\n";
	}	
	for(i=0; i<myarray.length;i++)
	{
		message += myarray[i];
		if (output)
		{
			message += "\n";
		}
		else
		{
			message += ", ";
		}
	}
	if (output)
	{
		print(message);
	}
	return message;
}

// ****************************************************
// [FUNCTIONS] ARRAY MANAGEMENT FUNCTIONS
// ****************************************************
function UpdateSet(value, setName)
{
	for(i=0; i<setName.length; i++)
	{
		if (setName[i] == value)
		{
			// value already in the set: return
			return setName;
		}
	}
	// value not in the set: add it
	setName = Array.concat(setName, value);	
	return setName;
}

// ****************************************************
// [FUNCTIONS] INPUT/OUTPUT FILES MANAGEMENT FUNCTIONS
// ****************************************************
function ListAvailableImages(inputfolder, selectedChannel, imagesList)
{
	// Read input filenames list
	flist = getFileList(input);
	flist = Array.sort(flist);
	for (i = 0; i < flist.length; i++)
	{
		if (endsWith(flist[i], suffix) == false)
		{
			continue;
		}
		if (selectedChannel == "NA")
		{
			// All tif images are ok
			imagesList = Array.concat(imagesList, flist[i]);
			continue;
		}
		// Get channel name
		startIdx = lastIndexOf(flist[i], "-") + 1;
		endIdx = lastIndexOf(flist[i], ".");
		currChanName = substring(flist[i], startIdx, endIdx);
		// If the name of the channel for the current image is
		// the same as the selected channel, add it to the list
		if (currChanName == selectedChannel)
		{
			imagesList = Array.concat(imagesList, flist[i]);
		}
	}
	return imagesList;
		
}

// **************************************************************
// **************************************************************
function extractTesterImgs(input)
{
	list = getFileList(input);
	list = Array.sort(list);
	File.makeDirectory(input + File.separator + "trainerset");
	trainerset = input + File.separator + "trainerset";
	for (i = 0; i < list.length; i++) 
	{
		if(endsWith(list[i], suffix))
			curr_file = list[i];
	    	open(input + File.separator + curr_file);
	    	imagecount = i * 3;
	    	for (n = 0; n < 3; n++)
	    	{
	    		x = 100+(n * 200);
	    		makeRectangle(x, x, 200, 200);
	    		run("Copy");
	    		run("Internal Clipboard");
	    		testercount = imagecount + n;
	    		saveAs("Tiff", trainerset + File.separator + "tester" + testercount);
	    		close();
	    		run("Collect Garbage");	    	
	    	}	
		close();
		run("Collect Garbage");
	}		
}
//END of FUNCTION

// Channel Merger
function channelMerger(input)
{
	listVEC = getFileList(input+File.separator+"VEC_St");
	listVEC = Array.sort(listVEC);
	listNUC = getFileList(input+File.separator+"NUC_St");
	listNUC = Array.sort(listNUC);
	File.makeDirectory(input + File.separator + "VEC_NUC");
	vecNuc = input + File.separator + "VEC_NUC";
	for (i = 0; i < listVEC.length; i++) 
	{
		if(endsWith(listVEC[i], suffix))
			curr_fileVEC = listVEC[i];
			curr_fileNUC = listNUC[i];
	    	open(input + File.separator + "VEC_St" + File.separator + curr_fileVEC);
	    	open(input + File.separator + "NUC_St" + File.separator + curr_fileNUC);
	    	imageCalculator("Add create", curr_fileVEC , curr_fileNUC);
	    	run("Gaussian Blur...", "sigma=3");
	    	saveAs("Tiff", vecNuc + File.separator + curr_fileNUC + "_VEC");
	    	run("Close All");
	    	run("Collect Garbage");	    		    	
	}		
}
//END of FUNCTION______________________________________

//Begin Function______________________________________
//Process foder generic with Original List (may be different from input but firs 12 char in names must match)
function processFolder(input, output, listorig) 
{
	list = getFileList(listorig);
	list = Array.sort(list);
	
	//For Nuclei
	//File.makeDirectory(output + File.separator + "NUC_St");
	//outDir = output + File.separator + "NUC_St";
	
	//For NOTCH
	//File.makeDirectory(output + File.separator + "NCH");
	//outDir = output + File.separator + "NCH";

	//For Cytosk Pha
	File.makeDirectory(output + File.separator + "PHA");
	outDir = output + File.separator + "PHA";
	
	for (i = 0; i < list.length; i++) 
	{
		cur_file = list[i];
		file_id = substring(cur_file, 0, 12);
		compl_file_id = file_id + "-ch3sk1fk1fl1.tiff";
		print(file_id);
		print(compl_file_id);
		//if(endsWith(list[i], suffix))
		processFile(input, outDir, compl_file_id);
	}
}

function processFile(input, output, cur_file) 
{
	// Mod Images	
	open(input + File.separator + cur_file);
	name_wo_suf = File.nameWithoutExtension;
	run("Scale...", "x=0.5 y=0.5 width=1080 height=1080 interpolation=Bilinear average create");		

	//For Nuclei
	//run("Enhance Contrast", "saturated=0.35"); -Not necessary-
	//run("Apply LUT");	-Not necessary-
	//saveAs("Tiff", output + File.separator + substring(name_wo_suf, 0, 12) + "_NUC");

	//For NOTCH
	//run("Subtract Background...", "rolling=300 sliding");	
	//run("Enhance Contrast", "saturated=0.35");
	//run("Apply LUT");
	//run("Unsharp Mask...", "radius=1 mask=0.80");	
	

	//For Pha
	run("Subtract Background...", "rolling=150 sliding");	
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	run("Unsharp Mask...", "radius=1 mask=0.70");
	saveAs("Tiff", output + File.separator + substring(name_wo_suf, 0, 12) + "_PHA");
	run("Close All");
	run("Collect Garbage");
}

//END FUNCTION______________________________________

//Begin function______________________________________
// Proces Folder Cytosk
function processFolderCytosk(input) 
{
	list = getFileList(input);
	list = Array.sort(list);
	File.makeDirectory(input + File.separator + "IlluminationCorr");
	IlluminationCorr = input + File.separator + "IlluminationCorr";
	for (i = 0; i < list.length; i++) 
	{
		cur_file = list[i];
		print(cur_file);
		if(endsWith(list[i], suffix) && (indexOf(cur_file, "ch3") == 13))
			processFileCy(input, IlluminationCorr, list[i]);
	}
}

function processFileCy(input, output, cur_file) 
{
	// Select PHA images (No need for Illumination corr on PHA)	
	open(input + File.separator + cur_file);
	name_wo_suf = File.nameWithoutExtension;
	run("Scale...", "x=0.5 y=0.5 width=1080 height=1080 interpolation=Bilinear average create");
	run("Enhance Contrast", "saturated=0.35");
	saveAs("Tiff", output + File.separator + substring(name_wo_suf, 0, 12)+"_PHA_IC");
	run("Close All");
	run("Collect Garbage");
}
//END FUNCTION______________________________________

function processFolderVEC(input) 
{
	list = getFileList(input);
	list = Array.sort(list);
	File.makeDirectory(input + File.separator + "IlluminationCorr");
	IlluminationCorr = input + File.separator + "IlluminationCorr";
	for (i = 0; i < list.length; i++) 
	{
		cur_file = list[i];
		print(cur_file);
		if(endsWith(list[i], suffix) && (indexOf(cur_file, "ch1") == 13))
			processFileVec(input, IlluminationCorr, list[i]);
	}
}

function processFileVec(input, output, cur_file) 
{
	// Select VEC images and correct illumination	
	open(input + File.separator + cur_file);
	name_wo_suf = File.nameWithoutExtension;
	run("Scale...", "x=0.5 y=0.5 width=1080 height=1080 interpolation=Bilinear average create");
	run("Duplicate...", " ");
	run("Gaussian Blur...", "sigma=200");
	run("Subtract...", "value=2750");
	imageCalculator("Subtract create", name_wo_suf+"-1.tiff", name_wo_suf+"-2.tiff");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	saveAs("Tiff", output + File.separator + substring(name_wo_suf, 0, 12)+"_VEC_IC");
	run("Close All");
	run("Collect Garbage");
}

function segmentResultsJunct(input)
{
    list = getFileList(input);
	list = Array.sort(list);
	File.makeDirectory(input + File.separator + "probMap");
	probMap = input + File.separator + "probMap";
	
	//run("Trainable Weka Segmentation");
	// wait for the plugin to load
	//wait(3000);
	//selectWindow("Trainable Weka Segmentation v3.3.1");
	//call("trainableSegmentation.Weka_Segmentation.loadClassifier", "/Volumes/LO KCL/Vinod Patel/Snap/Vessels-Matrix.model");
	
	for (i = 0; i < list.length; i++) 
	{
		//if(File.isDirectory(input + File.separator + list[i]))
			//processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))		
		//Weka segmentation
		selectWindow("Trainable Weka Segmentation v3.3.1");
		call("trainableSegmentation.Weka_Segmentation.applyClassifier", output , list[i] , "showResults=true", "storeResults=false", "probabilityMaps=true", "");
		name_wo_suf = File.nameWithoutExtension;
		close();		
		saveAs("Tiff", probMap + File.separator + name_wo_suf + "_PM");
		close();
		run("Collect Garbage");
}

function analyseMets(input)
{
    list = getFileList(input);
	list = Array.sort(list);
	//File.makeDirectory(input + File.separator + "threshMets");
	//thrmets = input + File.separator + "threshMets";
	run("Set Measurements...", "area redirect=None decimal=2");	
	for (i = 0; i < list.length; i++) 
	{
		if(endsWith(list[i], suffix))
		curr_file = list[i];
	    namelength = lengthOf(curr_file);
        indexfname = namelength - 19;
	    //Measure mets	   	
	    open(input + File.separator + curr_file );
	    setThreshold(0, 0);
        run("Convert to Mask");        
        rename("Mets_"+ substring(curr_file, 0, indexfname));
		run("Analyze Particles...", "size=100-Infinity summarize");
			//name_wo_suf = File.nameWithoutExtension;
			//saveAs("Tiff", thrmets + File.separator + name_wo_suf + "_mthr");
		close();
		run("Collect Garbage");
		//Measure Fibrotic tissue
		open(input + File.separator + curr_file );
        setThreshold(3, 3);
        run("Convert to Mask");
        rename("Fibro_"+substring(curr_file, 0, indexfname));
        run("Analyze Particles...", "size=50-Infinity summarize");
		close();
		run("Collect Garbage");
		//Measure total tissue
		open(input + File.separator + curr_file );
	    setThreshold(0, 1);
        run("Convert to Mask");
        open(input + File.separator + curr_file );
        setThreshold(3, 3);
        run("Convert to Mask");
        name_wo_suf = File.nameWithoutExtension;
        imageCalculator("Add", curr_file, name_wo_suf+"-1.tif");
        rename("Tissue_"+substring(curr_file, 0, indexfname));
		run("Analyze Particles...", "size=50-Infinity summarize");		
			//saveAs("Tiff", thrmets + File.separator + name_wo_suf + "_mthr");
		close("Tissue_"+substring(curr_file, 0, indexfname));
		close(name_wo_suf+"-1.tif");
		run("Collect Garbage");
	}
selectWindow("Summary");
saveAs("Results", input + File.separator + "Results.csv");
run("Close")
//selectWindow("Results");
//run("Close")
}
//End of Fo Function

//Start of functions
function processFolderPM(input) 
{
	list = getFileList(input);
	list = Array.sort(list);
	File.makeDirectory(input + File.separator + "VEC_Strict_PM_Classes");
	VEC_Strict_PM_Classes = input + File.separator + "VEC_Strict_PM_Classes";
	for (i = 0; i < list.length; i++) 
	{
		cur_file = list[i];
		if(endsWith(list[i], suffix))
			processFilePM(input, VEC_Strict_PM_Classes, list[i]);
	}
}

function processFilePM(input, output, cur_file) 
{
	// Mod Images	
	open(input + File.separator + cur_file);
	name_wo_suf = File.nameWithoutExtension;
	run("8-bit");
	run("Stack to Images");
	selectWindow("class 2");
	saveAs("Tiff", output + File.separator + substring(name_wo_suf, 0, 12) + "_CPM_Str");
	run("Close");
	selectWindow("class 1");
	saveAs("Tiff", output + File.separator + substring(name_wo_suf, 0, 12) + "_JPM_Str");
	run("Close All");
	run("Collect Garbage");
}
//END FUNCTION

//start function
function createMask(input)
{
	newImage("MaskSquares10", "8-bit white", 1080, 1080, 1);
	setForegroundColor(0, 0, 0);
	for (i=0; i<108; i++)
	{
		y = (i*11);
		makeLine(0, y, 1080, y);
		run("Draw", "slice");
		evod = (i%2);
		for (j=0; j<71; j++)
		{
			
			if(evod == 0) 
			{
				x = (j*41);
				makeLine(x, y, x, (y+10));
				run("Draw", "slice");
				}
			else 
			{
				x1 = (j*41)-20;
				makeLine(x1, y, x1, (y+10));
				run("Draw", "slice");
			}
		}
	}
	
}

//END of Function
