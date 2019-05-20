/** 
 * This file is part of AMUSE framework (Advanced MUsic Explorer).
 * 
 * Copyright 2006-2019 by code authors
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
 * Creation date: 01.06.2018
 */
package amuse.nodes.trainer.methods.supervised;

import amuse.data.ClassificationType;
import amuse.data.io.DataSet;
import amuse.data.io.DataSetInput;
import amuse.interfaces.nodes.methods.AmuseTask;
import amuse.interfaces.nodes.NodeException;
import amuse.nodes.classifier.ClassificationConfiguration;
import amuse.nodes.trainer.TrainingConfiguration;
import amuse.nodes.trainer.interfaces.TrainerInterface;
import amuse.util.LibraryInitializer;

import java.io.File;

import com.rapidminer.Process;
import com.rapidminer.operator.IOContainer;
import com.rapidminer.operator.IOObject;
import com.rapidminer.operator.Model;
import com.rapidminer.operator.Operator;
import com.rapidminer.operator.io.ModelWriter;
import com.rapidminer.operator.learner.Learner;
import com.rapidminer.operator.ports.InputPort;
import com.rapidminer.operator.ports.OutputPort;
import com.rapidminer.tools.OperatorService;
import com.rapidminer.operator.learner.lazy.KNNLearner;

/**
 * Adapter for fuzzy k-Nearest Neighbors.
 * 
 * @author Philipp Ginsel
 */
public class FKNNAdapter extends AmuseTask implements TrainerInterface {

	/** The number of neighbours */
	private int neighbourNumber;
	
	/**
	 * @see amuse.nodes.trainer.interfaces.TrainerInterface#setParameters(String)
	 */
	public void setParameters(String parameterString) {

		// Default parameters?
		if(parameterString == "" || parameterString == null) {
			neighbourNumber = 1;
		} else { 
			neighbourNumber = new Integer(parameterString);
		}
	}
	
	/*
	 * (non-Javadoc)
	 * @see amuse.interfaces.AmuseTaskInterface#initialize()
	 */
	public void initialize() throws NodeException {
		//Does nothing
	}
	
	/*
	 * (non-Javadoc)
	 * @see amuse.nodes.trainer.interfaces.TrainerInterface#trainModel(java.lang.String, java.lang.String, long)
	 */
	public void trainModel(String outputModel) throws NodeException {
		//test if the settings are supported
		if(((ClassificationConfiguration)this.correspondingScheduler.getConfiguration()).getClassificationType() == ClassificationType.UNSUPERVISED) {
			throw new NodeException("Unsupervised classification is not supported by this method.");
		}
		DataSet dataSet = ((DataSetInput)((TrainingConfiguration)this.correspondingScheduler.getConfiguration()).getGroundTruthSource()).getDataSet();
		
		// save the complete data since FKNN is not trained
		try {
			dataSet.saveToArffFile(new File(outputModel));
			
		} catch (Exception e) {
			throw new NodeException("Classification training failed: " + e.getMessage());
		}
	}

}