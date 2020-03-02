
// -------------------------------------------
// Disclaimer: this code is dirty in the
// meaning that there is no attention paid to
// proper class attribute access, memory
// management or optimisation of any kind. It
// is designed for quick-and-dirty testing
// purpose.
// -------------------------------------------

#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <string>
#include <cstdio>
#include <cstdlib>

#include <algorithm>
#include <GL/glut.h>
#include <float.h>
#include "src/Vec3.h"
#include "src/Camera.h"
#include "src/jmkdtree.h"




std::vector< Vec3 > positions;
std::vector< Vec3 > normals;

std::vector< Vec3 > positionsToProject;
std::vector< Vec3 > normalsToProject;

std::vector< Vec3 > positionsProjected;
std::vector< Vec3 > normalsProjected;


float pointSize = 2.f;
bool drawInputPointset = true;
bool drawPointsetToProject = true;
bool drawPointsetProjected = true;


// -------------------------------------------
// OpenGL/GLUT application code.
// -------------------------------------------

static GLint window;
static unsigned int SCREENWIDTH = 640;
static unsigned int SCREENHEIGHT = 480;
static Camera camera;
static bool mouseRotatePressed = false;
static bool mouseMovePressed = false;
static bool mouseZoomPressed = false;
static int lastX=0, lastY=0, lastZoom=0;
static bool fullScreen = false;




// ------------------------------------------------------------------------------------------------------------
// i/o and some stuff
// ------------------------------------------------------------------------------------------------------------
void loadPN (const std::string & filename , std::vector< Vec3 > & o_positions , std::vector< Vec3 > & o_normals ) {
    unsigned int surfelSize = 6;
    FILE * in = fopen (filename.c_str (), "rb");
    if (in == NULL) {
        std::cout << filename << " is not a valid PN file." << std::endl;
        return;
    }
    size_t READ_BUFFER_SIZE = 1000; // for example...
    float * pn = new float[surfelSize*READ_BUFFER_SIZE];
    o_positions.clear ();
    o_normals.clear ();
    while (!feof (in)) {
        unsigned numOfPoints = fread (pn, 4, surfelSize*READ_BUFFER_SIZE, in);
        for (unsigned int i = 0; i < numOfPoints; i += surfelSize) {
            o_positions.push_back (Vec3 (pn[i], pn[i+1], pn[i+2]));
            o_normals.push_back (Vec3 (pn[i+3], pn[i+4], pn[i+5]));
        }

        if (numOfPoints < surfelSize*READ_BUFFER_SIZE) break;
    }
    fclose (in);
    delete [] pn;
}
void savePN (const std::string & filename , std::vector< Vec3 > const & o_positions , std::vector< Vec3 > const & o_normals ) {
    if ( o_positions.size() != o_normals.size() ) {
        std::cout << "The pointset you are trying to save does not contain the same number of points and normals." << std::endl;
        return;
    }
    FILE * outfile = fopen (filename.c_str (), "wb");
    if (outfile == NULL) {
        std::cout << filename << " is not a valid PN file." << std::endl;
        return;
    }
    for(unsigned int pIt = 0 ; pIt < o_positions.size() ; ++pIt) {
        fwrite (&(o_positions[pIt]) , sizeof(float), 3, outfile);
        fwrite (&(o_normals[pIt]) , sizeof(float), 3, outfile);
    }
    fclose (outfile);
}
void scaleAndCenter( std::vector< Vec3 > & io_positions ) {
    Vec3 bboxMin( FLT_MAX , FLT_MAX , FLT_MAX );
    Vec3 bboxMax( FLT_MIN , FLT_MIN , FLT_MIN );
    for(unsigned int pIt = 0 ; pIt < io_positions.size() ; ++pIt) {
        for( unsigned int coord = 0 ; coord < 3 ; ++coord ) {
            bboxMin[coord] = std::min<float>( bboxMin[coord] , io_positions[pIt][coord] );
            bboxMax[coord] = std::max<float>( bboxMax[coord] , io_positions[pIt][coord] );
        }
    }
    Vec3 bboxCenter = (bboxMin + bboxMax) / 2.f;
    float bboxLongestAxis = std::max<float>( bboxMax[0]-bboxMin[0] , std::max<float>( bboxMax[1]-bboxMin[1] , bboxMax[2]-bboxMin[2] ) );
    for(unsigned int pIt = 0 ; pIt < io_positions.size() ; ++pIt) {
        io_positions[pIt] = (io_positions[pIt] - bboxCenter) / bboxLongestAxis;
    }
}

void applyRandomRigidTransformation( std::vector< Vec3 > & io_positions , std::vector< Vec3 > & io_normals ) {
    srand(time(NULL));
    Mat3 R = Mat3::RandRotation();
    Vec3 t = Vec3::Rand(1.f);
    for(unsigned int pIt = 0 ; pIt < io_positions.size() ; ++pIt) {
        io_positions[pIt] = R * io_positions[pIt] + t;
        io_normals[pIt] = R * io_normals[pIt];
    }
}

void subsample( std::vector< Vec3 > & i_positions , std::vector< Vec3 > & i_normals , float minimumAmount = 0.1f , float maximumAmount = 0.2f ) {
    std::vector< Vec3 > newPos , newNormals;
    std::vector< unsigned int > indices(i_positions.size());
    for( unsigned int i = 0 ; i < indices.size() ; ++i ) indices[i] = i;
    srand(time(NULL));
    std::random_shuffle(indices.begin() , indices.end());
    unsigned int newSize = indices.size() * (minimumAmount + (maximumAmount-minimumAmount)*(float)(rand()) / (float)(RAND_MAX));
    newPos.resize( newSize );
    newNormals.resize( newSize );
    for( unsigned int i = 0 ; i < newPos.size() ; ++i ) {
        newPos[i] = i_positions[ indices[i] ];
        newNormals[i] = i_normals[ indices[i] ];
    }
    i_positions = newPos;
    i_normals = newNormals;
}

bool save( const std::string & filename , std::vector< Vec3 > & vertices , std::vector< unsigned int > & triangles ) {
    std::ofstream myfile;
    myfile.open(filename.c_str());
    if (!myfile.is_open()) {
        std::cout << filename << " cannot be opened" << std::endl;
        return false;
    }

    myfile << "OFF" << std::endl;

    unsigned int n_vertices = vertices.size() , n_triangles = triangles.size()/3;
    myfile << n_vertices << " " << n_triangles << " 0" << std::endl;

    for( unsigned int v = 0 ; v < n_vertices ; ++v ) {
        myfile << vertices[v][0] << " " << vertices[v][1] << " " << vertices[v][2] << std::endl;
    }
    for( unsigned int f = 0 ; f < n_triangles ; ++f ) {
        myfile << 3 << " " << triangles[3*f] << " " << triangles[3*f+1] << " " << triangles[3*f+2];
        myfile << std::endl;
    }
    myfile.close();
    return true;
}










// ------------------------------------------------------------------------------------------------------------
// rendering.
// ------------------------------------------------------------------------------------------------------------

void initLight () {
    GLfloat light_position1[4] = {22.0f, 16.0f, 50.0f, 0.0f};
    GLfloat direction1[3] = {-52.0f,-16.0f,-50.0f};
    GLfloat color1[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    GLfloat ambient[4] = {0.3f, 0.3f, 0.3f, 0.5f};

    glLightfv (GL_LIGHT1, GL_POSITION, light_position1);
    glLightfv (GL_LIGHT1, GL_SPOT_DIRECTION, direction1);
    glLightfv (GL_LIGHT1, GL_DIFFUSE, color1);
    glLightfv (GL_LIGHT1, GL_SPECULAR, color1);
    glLightModelfv (GL_LIGHT_MODEL_AMBIENT, ambient);
    glEnable (GL_LIGHT1);
    glEnable (GL_LIGHTING);
}

void init () {
    camera.resize (SCREENWIDTH, SCREENHEIGHT);
    initLight ();
    glCullFace (GL_BACK);
    glDisable (GL_CULL_FACE);
    glDepthFunc (GL_LESS);
    glEnable (GL_DEPTH_TEST);
    glClearColor (1.f, 1.f, 1.f, 1.0f);
    glEnable(GL_COLOR_MATERIAL);
}


//---------------------------------------------------------------------//
// The following function can be used to render a triangle mesh
// It takes as input:
// - a set of 3d points
// - a set of point indices: 3 consecutive indices make a triangle.
//   for example, if i_triangles = { 0 , 4 , 1 , 3 , 2 , 5 , ... },
//   then the first two triangles will be composed of
//     {i_positions[0], i_positions[4] , i_positions[1] } and
//     {i_positions[3], i_positions[2] , i_positions[5] }
void drawTriangleMesh( std::vector< Vec3 > const & i_positions , std::vector< unsigned int > const & i_triangles ) {
    glBegin(GL_TRIANGLES);
    for(unsigned int tIt = 0 ; tIt < i_triangles.size() / 3 ; ++tIt) {
        Vec3 p0 = i_positions[i_triangles[3*tIt]];
        Vec3 p1 = i_positions[i_triangles[3*tIt+1]];
        Vec3 p2 = i_positions[i_triangles[3*tIt+2]];
        Vec3 n = Vec3::cross(p1-p0 , p2-p0);
        n.normalize();
        glNormal3f( n[0] , n[1] , n[2] );
        glVertex3f( p0[0] , p0[1] , p0[2] );
        glVertex3f( p1[0] , p1[1] , p1[2] );
        glVertex3f( p2[0] , p2[1] , p2[2] );
    }
    glEnd();
}

// The following function can be used to render a pointset
void drawPointSet( std::vector< Vec3 > const & i_positions , std::vector< Vec3 > const & i_normals ) {
    glBegin(GL_POINTS);
    for(unsigned int pIt = 0 ; pIt < i_positions.size() ; ++pIt) {
        glNormal3f( i_normals[pIt][0] , i_normals[pIt][1] , i_normals[pIt][2] );
        glVertex3f( i_positions[pIt][0] , i_positions[pIt][1] , i_positions[pIt][2] );
    }
    glEnd();
}







void draw () {
    glPointSize(pointSize); // for example...

    glColor3f(0.8,0.8,1);
    if( drawInputPointset )
        drawPointSet(positions , normals);

    glColor3f(1,0.5,0.5);
    if( drawPointsetToProject )
        drawPointSet(positionsToProject , normalsToProject);

    glColor3f(0.5,0.8,0.5);
    if( drawPointsetProjected )
        drawPointSet(positionsProjected , normalsProjected);
}








void display () {
    glLoadIdentity ();
    glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    camera.apply ();
    draw ();
    glFlush ();
    glutSwapBuffers ();
}

void idle () {
    glutPostRedisplay ();
}

void key (unsigned char keyPressed, int x, int y) {
    switch (keyPressed) {
    case 'f':
        if (fullScreen == true) {
            glutReshapeWindow (SCREENWIDTH, SCREENHEIGHT);
            fullScreen = false;
        } else {
            glutFullScreen ();
            fullScreen = true;
        }
        break;

    case 'w':
        GLint polygonMode[2];
        glGetIntegerv(GL_POLYGON_MODE, polygonMode);
        if(polygonMode[0] != GL_FILL)
            glPolygonMode (GL_FRONT_AND_BACK, GL_FILL);
        else
            glPolygonMode (GL_FRONT_AND_BACK, GL_LINE);
        break;

    case 'a':
        pointSize /= 1.1;
        break;
    case 'z':
        pointSize *= 1.1;
        break;
    case '1':
        drawInputPointset = !drawInputPointset;
        break;
    case '2':
        drawPointsetToProject = !drawPointsetToProject;
        break;
    case '3':
        drawPointsetProjected = !drawPointsetProjected;
        break;

    default:
        break;
    }
    idle ();
}

void mouse (int button, int state, int x, int y) {
    if (state == GLUT_UP) {
        mouseMovePressed = false;
        mouseRotatePressed = false;
        mouseZoomPressed = false;
    } else {
        if (button == GLUT_LEFT_BUTTON) {
            camera.beginRotate (x, y);
            mouseMovePressed = false;
            mouseRotatePressed = true;
            mouseZoomPressed = false;
        } else if (button == GLUT_RIGHT_BUTTON) {
            lastX = x;
            lastY = y;
            mouseMovePressed = true;
            mouseRotatePressed = false;
            mouseZoomPressed = false;
        } else if (button == GLUT_MIDDLE_BUTTON) {
            if (mouseZoomPressed == false) {
                lastZoom = y;
                mouseMovePressed = false;
                mouseRotatePressed = false;
                mouseZoomPressed = true;
            }
        }
    }
    idle ();
}

void motion (int x, int y) {
    if (mouseRotatePressed == true) {
        camera.rotate (x, y);
    }
    else if (mouseMovePressed == true) {
        camera.move ((x-lastX)/static_cast<float>(SCREENWIDTH), (lastY-y)/static_cast<float>(SCREENHEIGHT), 0.0);
        lastX = x;
        lastY = y;
    }
    else if (mouseZoomPressed == true) {
        camera.zoom (float (y-lastZoom)/SCREENHEIGHT);
        lastZoom = y;
    }
}


void reshape(int w, int h) {
    camera.resize (w, h);
}













void HPSS( Vec3 inputPoint, // the point you need to project
           Vec3 & outputPoint , Vec3 & outputNormal , // the projection (and the normal at the projection)
           std::vector< Vec3 > const & inputPositions , std::vector< Vec3 > const & inputNormals , // the input pointset on which you want to project
           BasicANNkdTree const & inputPointsetKdTree , // the input pointset kdtree: it can help you find the points that are nearest to a query point
           int kernel_type , float radius, // the parameters for the MLS surface (a kernel can be i) a Gaussian, ii) Wendland, iii) Singular
           unsigned int numberOfIterations , // the number of iterations of the MLS algorithm
           unsigned int knn = 20 ) { // the number of nearest neighbors you will consider when computing the MLS projection
    // TO CHANGE:
    outputPoint = inputPoint;
    for( unsigned int k = 0 ; k < numberOfIterations ; k++ ){

      // Génération des vecteurs avec les ppv et les distances respectives
      ANNidxArray id_nearest_neighbors = new ANNidx[knn];
      ANNdistArray square_distances_to_neighbors = new ANNdist[knn];
      inputPointsetKdTree.knearest(outputPoint, knn, id_nearest_neighbors, square_distances_to_neighbors);
      //Initialisations
      std::vector<Vec3> projections;
      float * w = new float[knn]; //vecteur des poids (dépend du kernel choisi)
      Vec3 n = Vec3(0,0,0);
      Vec3 c = Vec3(0,0,0);
      float c_denom = 0;

      for( unsigned int i = 0 ; i < knn ; i++ ){
        //MAJ de center, de la normale
        int index = id_nearest_neighbors[i];
        projections.push_back(outputPoint-(Vec3::dot(outputPoint-inputPositions[index],inputNormals[index]))*inputNormals[index]);

        if (kernel_type==0){
          w[i] = 1.0/(sqrt(2*3.14)/radius)*exp(-square_distances_to_neighbors[i]/(2*(radius*radius)));
          c = c + w[i]*projections[i];
          n = n+ w[i]*inputNormals[index];
          c_denom = c_denom + w[i];
        }

        if (kernel_type==1){
          w[i] = (1+4*square_distances_to_neighbors[i]/radius)*pow((1-(square_distances_to_neighbors[i])/radius),4);
          c = c + w[i]*projections[i];
          n = n+ w[i]*inputNormals[index];
          c_denom = c_denom + w[i];
        }




      }

      delete[] id_nearest_neighbors;
      delete[] square_distances_to_neighbors;

      //projection
      c = c/c_denom;
      n.normalize();
      outputPoint = outputPoint - Vec3::dot(outputPoint-c,n)*n;
      outputNormal = n;

    }
}






int main (int argc, char ** argv) {
    if (argc > 2) {
        exit (EXIT_FAILURE);
    }
    glutInit (&argc, argv);
    glutInitDisplayMode (GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);
    glutInitWindowSize (SCREENWIDTH, SCREENHEIGHT);
    window = glutCreateWindow ("tp point processing");

    init ();
    glutIdleFunc (idle);
    glutDisplayFunc (display);
    glutKeyboardFunc (key);
    glutReshapeFunc (reshape);
    glutMotionFunc (motion);
    glutMouseFunc (mouse);
    key ('?', 0, 0);


    {
        // Load a first pointset, and build a kd-tree:
        loadPN("pointsets/igea.pn" , positions , normals);

        BasicANNkdTree kdtree;
        kdtree.build(positions);

        // Create a second pointset that is artificial, and project it on pointset1 using MLS techniques:
        positionsToProject.resize( 20000 );
        normalsToProject.resize(positionsToProject.size());
        for( unsigned int pIt = 0 ; pIt < positionsToProject.size() ; ++pIt ) {
            positionsToProject[pIt] = Vec3(
                        -0.6 + 1.2 * (double)(rand())/(double)(RAND_MAX),
                        -0.6 + 1.2 * (double)(rand())/(double)(RAND_MAX),
                        -0.6 + 1.2 * (double)(rand())/(double)(RAND_MAX)
                        );
            positionsToProject[pIt].normalize();
            positionsToProject[pIt] = 0.6 * positionsToProject[pIt];
        }

        // IF YOU WANT TO TAKE AS POINTSET TO PROJECT THE INPUT POINTSET ITSELF: USEFUL FOR POINTSET FILTERING
        if( false ) {
            positionsToProject = positions;
            normalsToProject = normals;
        }

        // INITIALIZE THE PROJECTED POINTSET (USEFUL MAINLY FOR MEMORY ALLOCATION)
        positionsProjected.resize(positionsToProject.size());
        normalsProjected.resize(positionsToProject.size());


        // PROJECT USING MLS (HPSS, and later APSS):
        for( unsigned int pIt = 0 ; pIt < positionsToProject.size() ; ++pIt ) {
            Vec3 oP, oN;
            HPSS( positionsToProject[pIt] , oP , oN , positions , normals , kdtree , 0 , 0.1 , 5 , 20 ); // for example
            positionsProjected[pIt] = oP;
            normalsProjected[pIt] = oN;
        }
    }



    glutMainLoop ();
    return EXIT_SUCCESS;
}
