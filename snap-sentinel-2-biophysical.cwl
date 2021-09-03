$graph:
- class: Workflow
  id: main

  label: S2 Biophysical
  doc: Sentinel-2 Biophysical Parameters 

  inputs:
    safe:
      doc: Sentinel-2 SAFE Directory
      label: Sentinel-2 SAFE Directory
      type: Directory[]

  outputs:
  - id: wf_outputs
    outputSource:
    - node_snap/results
    type:
      items: File
      type: array
  
  requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  
  steps:

    node_snap:
  
      in:
        safe: safe
  
      out:
      - results
      
      run: '#clt'

      scatter: safe
      scatterMethod: dotproduct

- class: CommandLineTool

  id: clt

  baseCommand: [ gpt, biophysical.xml ] 

  arguments:
  - prefix: -POutput=
    position: 3
    separate: false
    valueFrom: |
          ${ 
              return inputs.safe.basename.replace(".SAFE", ".tif"); 
          }
  inputs:
  
    safe:
      inputBinding:
        position: 2
        prefix: -PInput=
        separate: false
      type: Directory
  
  outputs:
  
    results:
      outputBinding:
        glob: '*.tif'
      type: File

  requirements:
    EnvVarRequirement:
      envDef: 
        PATH: /srv/conda/envs/env_snap/snap/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
    ResourceRequirement: {}
    InlineJavascriptRequirement: {}
    DockerRequirement:
      dockerPull: docker.pkg.github.com/cwl-for-eo/containers/snap-gpt:latest
    InitialWorkDirRequirement:
      listing:
        - entryname: biophysical.xml
          entry: |-
            <graph id="Graph">
                <version>1.0</version>
                <node id="Read">
                    <operator>Read</operator>
                    <sources/>
                    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
                    <file>$Input</file>
                    </parameters>
                </node>
                <node id="Resample">
                    <operator>Resample</operator>
                    <sources>
                    <sourceProduct refid="Read"/>
                    </sources>
                    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
                    <referenceBand>B2</referenceBand>
                    <targetWidth/>
                    <targetHeight/>
                    <targetResolution/>
                    <upsampling>Nearest</upsampling>
                    <downsampling>First</downsampling>
                    <flagDownsampling>First</flagDownsampling>
                    <resamplingPreset/>
                    <bandResamplings/>
                    <resampleOnPyramidLevels>true</resampleOnPyramidLevels>
                    </parameters>
                </node>
                <node id="BiophysicalOp">
                    <operator>BiophysicalOp</operator>
                    <sources>
                    <sourceProduct refid="Resample"/>
                    </sources>
                    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
                    <sensor>S2A</sensor>
                    <computeLAI>true</computeLAI>
                    <computeFapar>true</computeFapar>
                    <computeFcover>true</computeFcover>
                    <computeCab>true</computeCab>
                    <computeCw>true</computeCw>
                    </parameters>
                </node>
                <node id="Write">
                    <operator>Write</operator>
                    <sources>
                    <sourceProduct refid="BiophysicalOp"/>
                    </sources>
                    <parameters class="com.bc.ceres.binding.dom.XppDomElement">
                    <file>$Output</file>
                    <formatName>GeoTIFF-BigTIFF</formatName>
                    </parameters>
                </node>
            </graph>

cwlVersion: v1.0