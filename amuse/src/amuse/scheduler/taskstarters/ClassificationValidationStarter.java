/** 
 * This file is part of AMUSE framework (Advanced MUsic Explorer).
 * 
 * Copyright 2006-2010 by code authors
 * 
 * Created at TU Dortmund, Chair of Algorithm Engineering
 * (Contact: <http://ls11-www.cs.tu-dortmund.de>) 
 *
 * AMUSE is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * AMUSE is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with AMUSE. If not, see <http://www.gnu.org/licenses/>.
 * 
 * Creation date: 14.01.2008
 */
package amuse.scheduler.taskstarters;

import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.util.Properties;

import org.apache.log4j.Level;

import amuse.interfaces.nodes.NodeException;
import amuse.interfaces.nodes.TaskConfiguration;
import amuse.interfaces.scheduler.AmuseTaskStarter;
import amuse.interfaces.scheduler.SchedulerException;
import amuse.nodes.validator.ValidationConfiguration;
import amuse.nodes.validator.ValidatorNodeScheduler;
import amuse.preferences.AmusePreferences;
import amuse.preferences.KeysIntValue;
import amuse.preferences.KeysStringValue;
import amuse.util.AmuseLogger;

/**
 * This scheduler class starts validation of classifiers
 * 
 * @author Igor Vatolkin
 * @version $Id$
 */
public class ClassificationValidationStarter extends AmuseTaskStarter {

	/**
 	 * Constructor
	 */
	public ClassificationValidationStarter(String nodeFolder, long jobCounter, boolean startNodeDirectly) throws SchedulerException {
		super(nodeFolder,jobCounter,startNodeDirectly);
	}
	
	/*
	 * (non-Javadoc)
	 * @see amuse.interfaces.scheduler.AmuseTaskStarterInterface#startTask(amuse.interfaces.nodes.TaskConfiguration[], java.util.Properties)
	 */
	public long startTask(TaskConfiguration[] taskConfiguration, Properties props) throws SchedulerException {

		// Generate and proceed Amuse jobs
		for (int i = 0; i < taskConfiguration.length; i++) {
			
			// If the validator node scheduler will be started via grid or batch script...
			if (!this.startNodeDirectly) {
	   	   		
				// How many Amuse jobs should be proceeded to one grid machine?
				int numberOfJobsToMerge = AmusePreferences.getInt(KeysIntValue.NUMBER_OF_JOBS_PER_GRID_MACHINE); 
				if(taskConfiguration.length - i < numberOfJobsToMerge) {
					numberOfJobsToMerge = taskConfiguration.length - i;
				}
				ValidationConfiguration[] validatorConfig = new ValidationConfiguration[numberOfJobsToMerge];
				for(int k=0;k<numberOfJobsToMerge;k++) {
					validatorConfig[k] = (ValidationConfiguration)taskConfiguration[i];
					AmuseLogger.write(this.getClass().getName(), Level.INFO, "Validator task script for input "
							+ validatorConfig[k].getInputToValidate().toString() + " is prepared");
					i++;
				}
				i--; // Since the for-loop increments i  
				
				FileOutputStream fos = null;
	   	   		ObjectOutputStream out = null;
	   	   		try {
	   	   			fos = new FileOutputStream(new String(AmusePreferences.get(KeysStringValue.AMUSE_PATH) + File.separator + "taskoutput" + File.separator + "task_" + 
	   	   					this.jobCounter + ".ser"));
	   	   		    out = new ObjectOutputStream(fos);
	   	   		    out.writeObject(validatorConfig);
	   	   		    out.close();
	   	   	    } catch(IOException ex) {
	   	   		    ex.printStackTrace();
	   	   	    }
	   	    	    
	   	    	// Create parameter line
				String parameterString = new String();
				parameterString = new Long(this.jobCounter).toString();
				
				// Update the counter of batch jobs
				try {
					FileOutputStream values_toTest = new FileOutputStream(new File(AmusePreferences.get(KeysStringValue.AMUSE_PATH) + "/config/jobcounter.txt"));
					DataOutputStream values_writerTest = new DataOutputStream(values_toTest);
					values_writerTest.writeBytes(new Long(jobCounter+1).toString());
					values_toTest.close();
				} catch (Exception e) {
					throw new SchedulerException("Could not update job counter during proceeding a script to the grid: " + e.getMessage());
				}
		
				// Proceed script to grid
				Process process;
				try {
				    process = Runtime.getRuntime().exec(AmusePreferences.get(KeysStringValue.GRID_SCRIPT_VALIDATOR) + " " + parameterString);
				} catch (IOException e) {
				    throw new SchedulerException("Error on proceeding a script to the grid: " + e.getMessage());
				}
		
				// Wait till the job is proceeded to grid (otherwise "too many open files" exception may occur)
				try {
				    process.waitFor();
		
					// DEBUG Show the runtime outputs
					/*String s = null; 
					java.io.BufferedReader stdInput = new java.io.BufferedReader(new java.io.InputStreamReader(process.getInputStream()));
 			        java.io.BufferedReader stdError = new java.io.BufferedReader(new java.io.InputStreamReader(process.getErrorStream()));
					System.out.println("Here is the standard output of the command:\n"); 
					while ((s = stdInput.readLine()) != null) { System.out.println(s); } 
					System.out.println("Here is the standard error of the command (if any):\n"); 
					while ((s = stdError.readLine()) != null) { System.out.println(s); }*/
				} catch (Exception e) {
				    throw new SchedulerException("Problems at proceeding of jobs to grid: " + e.getMessage());
				}
	   	    } 
			
			// ... or if the validator node scheduler will be started directly
			else {
				ValidationConfiguration validatorConfig = (ValidationConfiguration)taskConfiguration[i];
				ValidatorNodeScheduler validatorThread = null;
				try {
					validatorThread = new ValidatorNodeScheduler(AmusePreferences.get(KeysStringValue.AMUSE_PATH) + 
							File.separator + "config" + File.separator + "node" + File.separator + "validator" + File.separator + "input" + File.separator + "task_" + this.jobCounter);
				} catch (NodeException e) {
					throw new SchedulerException("Validator node thread could not be started: " + e.getMessage());
				}
	
			    // Prepare validator node scheduler arguments and start it as thread
	   	    	validatorThread.setThreadParameters(AmusePreferences.get(KeysStringValue.AMUSE_PATH) + File.separator + "config" + File.separator + "node" + File.separator + "validator", this.jobCounter, validatorConfig);
			    Thread newValidatorThread = new Thread(validatorThread);
			    // TODO Timeout einbauen
			    while (this.nodeSchedulers.size() >= AmusePreferences.getInt(KeysIntValue.MAX_NUMBER_OF_TASK_THREADS)) {
					try {
					    Thread.sleep(1000);
					} catch (InterruptedException e) {
					    throw new SchedulerException(this.getClass().getName() + " was interrupted: " + e.getMessage());
					}
			    }
			    this.connectSchedulerToErrorDescriptionList(validatorThread);
			    nodeSchedulers.add(validatorThread);
			    validatorThread.addListener(this);
			    newValidatorThread.start();
			}
			this.jobCounter++;
		}
			
		// If the node schedulers are started directly (and not e.g. as grid scripts), wait until all jobs are ready
		if(this.startNodeDirectly) {
			
			// TODO Timeout einbauen!
			while(this.nodeSchedulers.size() > 0) {
				try {
					Thread.sleep(1000);
				} catch (InterruptedException e) {
					throw new SchedulerException(this.getClass().getName() + " was interrupted: " + e.getMessage());
				}
			}
		} 
		
		return this.jobCounter;
	}
	
}
