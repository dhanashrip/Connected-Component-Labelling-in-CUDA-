
// splits with tree

#include <stdlib.h>
#include <stdio.h>
#include <png.h>
#include <math.h>
#include <iostream>
#include <vector>
#include <cuda.h>
#include<cuda_runtime.h>
#include<assert.h>
using namespace std;

__global__ void merge(int *mat,struct tree* t1,struct tree* c1,struct tree* c2,struct tree* c3,struct tree* c4,unsigned int *, unsigned int * );

int width, height;
png_byte color_type;
png_byte bit_depth;
png_bytep *row_pointers;

struct tree
{
	int start1,end1,start2,end2,data,label;
	int fg1,fg2,fg3,fg4; // to find the adjacencies
	struct tree *c1,*c2,*c3,*c4;
}*root;

struct region
{
	int x1,y1,x2,y2,x3,y3,x4,y4,mean;
};
	int w=0,h=0;
	int **mat;
	static int count;
	vector<region> childs;
	int read_png_file(char *);
	void write_png_file(char *);
	void process_png_file(unsigned int);
	bool pred(int , int ,int ,int ,int *mat[]);
	int mean(int,int,int ,int ,int *mat[]);
	region split(region,int *mat[],unsigned int, struct tree*);
	//void merge(int *mat[],struct tree* t1,int );
	__host__ __device__ bool mergeregion(struct tree* t1, struct tree* t2);
	void labelling(int *mat[],struct tree* t1,struct tree* t2);
	void mergeglobe(int *mat[], struct tree* t1,struct tree* t2,struct tree* t3, struct tree* t4);
	void print(struct tree*);
	int get_height(struct tree*);
	void printlevelorder(struct tree*, unsigned int);
	void printgivenlevel(struct tree*,int, unsigned int);


int read_png_file(char *filename) {
  FILE *fp = fopen(filename, "rb");

  png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if(!png) abort();

  png_infop info = png_create_info_struct(png);
  if(!info) abort();

  if(setjmp(png_jmpbuf(png))) abort();

  png_init_io(png, fp);

  png_read_info(png, info);

  width      = png_get_image_width(png, info);
  height     = png_get_image_height(png, info);
  color_type = png_get_color_type(png, info);
  bit_depth  = png_get_bit_depth(png, info);

  if(bit_depth == 16)
    png_set_strip_16(png);

  if(color_type == PNG_COLOR_TYPE_PALETTE)
    png_set_palette_to_rgb(png);

  if(color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
    png_set_expand_gray_1_2_4_to_8(png);

  if(png_get_valid(png, info, PNG_INFO_tRNS))
    png_set_tRNS_to_alpha(png);

  if(color_type == PNG_COLOR_TYPE_RGB ||
     color_type == PNG_COLOR_TYPE_GRAY ||
     color_type == PNG_COLOR_TYPE_PALETTE)
    png_set_filler(png, 0xFF, PNG_FILLER_AFTER);

  if(color_type == PNG_COLOR_TYPE_GRAY ||
     color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
    png_set_gray_to_rgb(png);

  png_read_update_info(png, info);

  row_pointers = (png_bytep*)malloc(sizeof(png_bytep) * height);
  for(int y = 0; y < height; y++) {
    row_pointers[y] = (png_byte*)malloc(png_get_rowbytes(png,info));
  }

  png_read_image(png, row_pointers);
  cout << "Height" << height << "\t Width" << width ;
  fclose(fp);
  int max;
  if(height > width)
  {
	max=height;
  }
  else
  {
	max=width;
  }
  int next = pow(2,ceil(log(max)/log(2)));
  cout << "\nNext \t" << next;
  return next;
  
}


void write_png_file(char *filename) {
  int y;

  FILE *fp = fopen(filename, "wb");
  if(!fp) abort();

  png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png) abort();

  png_infop info = png_create_info_struct(png);
  if (!info) abort();

  if (setjmp(png_jmpbuf(png))) abort();

  png_init_io(png, fp);


  png_set_IHDR(
    png,
    info,
    width, height,
    8,
    PNG_COLOR_TYPE_RGBA,
    PNG_INTERLACE_NONE,
    PNG_COMPRESSION_TYPE_DEFAULT,
    PNG_FILTER_TYPE_DEFAULT
  );
  png_write_info(png, info);

  png_write_image(png, row_pointers);
  png_write_end(png, NULL);

  for(int y = 0; y < height; y++) {
    free(row_pointers[y]);
  }
  free(row_pointers);

  fclose(fp);
}
//to find height of tree
int get_height(struct tree *t)
{
	int m,k;
	if(t==NULL)
		return 0;
	else
		{
			int c1h = get_height(t->c1);
			int c2h = get_height(t->c2);
			int c3h = get_height(t->c3);
			int c4h = get_height(t->c4);
			if(c1h>c2h)
			{
				m=c1h;
			}
			else
			{
				m=c2h;
			}
			if(c3h>c4h)
			{
				k=c3h;
			}
			else
			{
				k=c4h;
			}
			if(k>m)
			{
				return (k+1);
			}
			else
			{
				return (m+1);
			}

		}
	             

}
void printlevelorder(struct tree *root,unsigned int m1)
{
	int h = get_height(root);
	
	int i;
	for(i=h;i>=1;i--)
	{
		cout << "\ni: " << i;
		printgivenlevel(root,i,m1);
		
	}
}
unsigned int label1 = 5;

void printgivenlevel(struct tree *root,int level,unsigned int m1)
{
	//cout << "\nLevel : " <<  level ;
int *p = new int[m1*m1];
int *mat2 = new int[m1*m1];
unsigned int *da;
unsigned int *lab;
	if(root==NULL)
		return;
	if(level==1)
	{
		cout << "\nNode: \t(" << root->start1 << "," << root->end1 << ") (" << root->start2 << "," << root->end2 << ")" << "\tData: " << root->data << "\tFG: " << root->fg1 << root->fg2 << root->fg3 << root->fg4;
		//cout << "\nLevel : " <<  level ;
	}
	else if(level>1)
		{
			printgivenlevel(root->c1,level-1,m1);
			printgivenlevel(root->c2,level-1,m1);
			printgivenlevel(root->c3,level-1,m1);
			printgivenlevel(root->c4,level-1,m1);
			cout << "\n Merge ";
			//cout << "\nT1: " << root->fg2;
			
			if(root->c1!=NULL && root->c2!=NULL && root->c3!=NULL && root->c4!=NULL)
			{
			
			//cout << "\nD ";
			for(int h =0; h < m1; h++)
			{
				for(int w =0; w < m1; w++)
				{
					p[m1*h + w] = mat[h][w];
					//cout << "\t " << p[m1*h + m1];
				}
				//cout << "\n";
			}
			/*cout << "\nPREE:\n";
			for(int h =0; h < m1; h++)
			{	
				for(int w =0; w < m1; w++)
				{
					cout<<"\t"<<p[m1*h + w];
				}
				cout<<"\n";
			}  */

			struct tree * tree_d,*tree_c1,*tree_c2,*tree_c3,*tree_c4;	
			tree_d = new tree();
			tree_c1 = new tree();
			tree_c2 = new tree();
			tree_c3 = new tree();
			tree_c4 = new tree();
					
			cudaMalloc((void **)&tree_d,  5* sizeof(struct  node*));
			cudaMalloc((void **)&tree_c1, 5*sizeof(struct node*));
			cudaMalloc((void **)&tree_c2, 5*sizeof(struct node*));
			cudaMalloc((void **)&tree_c3, 5*sizeof(struct node*));
			cudaMalloc((void **)&tree_c4, 5*sizeof(struct node*));			

			cudaMalloc((void **)&da,sizeof(unsigned int));
			cudaMalloc((void **)&mat2,sizeof(int)*m1*m1);
			cudaMalloc((void **)&lab,sizeof(unsigned int));
			cudaMemcpy(mat2,p,sizeof(int)*m1*m1,cudaMemcpyHostToDevice);
			cudaMemcpy(da,&m1,sizeof(unsigned int ),cudaMemcpyHostToDevice);
			cudaMemcpy(lab,&label1,sizeof(unsigned int ),cudaMemcpyHostToDevice);	

			cudaMemcpy(&(tree_d->start1),&( root->start1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_d->end1),&( root->end1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_d->start2),&( root->start2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_d->end2),&( root->end2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_d->data),&( root->data),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_d->label),&( root->label),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_d->fg1),&( root->fg1),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_d->fg2),&( root->fg2),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_d->fg3),&( root->fg3),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_d->fg4),&( root->fg4),sizeof(int), cudaMemcpyHostToDevice);	

			cudaMemcpy(&(tree_c1->start1),&( root->c1->start1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c1->end1),&( root->c1->end1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c1->start2),&( root->c1->start2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c1->end2),&( root->c1->end2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c1->data),&( root->c1->data),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c1->label),&( root->c1->label),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c1->fg1),&( root->c1->fg1),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c1->fg2),&( root->c1->fg2),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c1->fg3),&( root->c1->fg3),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c1->fg4),&( root->c1->fg4),sizeof(int), cudaMemcpyHostToDevice);	

			cudaMemcpy(&(tree_c2->start1),&( root->c2->start1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c2->end1),&( root->c2->end1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c2->start2),&( root->c2->start2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c2->end2),&( root->c2->end2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c2->data),&( root->c2->data),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c2->label),&( root->c2->label),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c2->fg1),&( root->c2->fg1),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c2->fg2),&( root->c2->fg2),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c2->fg3),&( root->c2->fg3),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c2->fg4),&( root->c2->fg4),sizeof(int), cudaMemcpyHostToDevice);	

			cudaMemcpy(&(tree_c3->start1),&( root->c3->start1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c3->end1),&( root->c3->end1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c3->start2),&( root->c3->start2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c3->end2),&( root->c3->end2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c3->data),&( root->c3->data),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c3->label),&( root->c3->label),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c3->fg1),&( root->c3->fg1),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c3->fg2),&( root->c3->fg2),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c3->fg3),&( root->c3->fg3),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c3->fg4),&( root->c3->fg4),sizeof(int), cudaMemcpyHostToDevice);	

			cudaMemcpy(&(tree_c4->start1),&( root->c4->start1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c4->end1),&( root->c4->end1),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c4->start2),&( root->c4->start2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c4->end2),&( root->c4->end2),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c4->data),&( root->c4->data),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c4->label),&( root->c4->label),sizeof(int), cudaMemcpyHostToDevice);
			cudaMemcpy(&(tree_c4->fg1),&( root->c4->fg1),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c4->fg2),&( root->c4->fg2),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c4->fg3),&( root->c4->fg3),sizeof(int), cudaMemcpyHostToDevice);	
			cudaMemcpy(&(tree_c4->fg4),&( root->c4->fg4),sizeof(int), cudaMemcpyHostToDevice);	

			merge<<<1,4>>>(mat2,tree_d,tree_c1,tree_c2,tree_c3,tree_c4,lab,da);
			cudaDeviceSynchronize();
			printf("\nSAM:");
			cudaMemcpy(p,mat2,sizeof(int)*m1*m1,cudaMemcpyDeviceToHost);
			/*
			for(int i = 0; i < m1; i++)
			{
				for(int j=0; j<m1; j++)
				{
					//mat[i][j] = mat1[m1*i + j];
					printf("%d\t",p[m1*i + j]);
				}
				printf("\n");
			}	*/
			for(int i = 0; i < m1; i++)
			{
				for(int j=0; j<m1; j++)
				{
					//mat[i][j] = mat1[m1*i + j];
					mat[i][j]=p[m1*i + j];
				}
				//printf("\n");
			}	
			//mergeglobe(mat,root->c1,root->c2,root->c3,root->c4);
			label1 = label1+4;
			cudaFree(tree_d);
			cudaFree(tree_c1);
			cudaFree(tree_c2);
			cudaFree(tree_c3);
			cudaFree(tree_c4);			
			cudaFree(da);
			cudaFree(mat2);
			cudaFree(lab);
		}
	
	}

}

//merge: 

__global__ void merge(int *mat1,struct tree* t1,struct tree* c1,struct tree* c2,struct tree* c3,struct tree* c4,unsigned int *label2,unsigned int *m2)
{
	//printf("\nkernel");
	t1->c1=c1;
	t1->c2=c2;
	t1->c3=c3;
	t1->c4=c4;	
	unsigned int m1 = *m2;
	unsigned int label1 = *label2;
	//printf("\nM1: %d",m1);
	int **mat = new int*[m1*m1];
	for( int i=0;i<m1;i++)
	{
		mat[i]=new int[m1];
	}
	for(int i = 0; i < m1; i++)
	{
		for(int j=0; j<m1; j++)
		{
			mat[i][j] = mat1[m1*i + j];
		}
	}
	/*printf("\nPRE\n");	
	for(int i = 0; i < m1; i++) 
	{
		for(int j=0; j<m1; j++)
		{
			printf("%d \t",mat[i][j]);
		}
		printf("\n");
	} */	
	bool row1=false,row2=false,col1=false,col2=false;
	if(t1->c1==NULL && t1->c2==NULL && t1->c3==NULL && t1->c4==NULL)
		return;

		row1 = mergeregion(t1->c1, t1->c2);
		row2 = mergeregion(t1->c3,t1->c4);
		col1 = mergeregion(t1->c1, t1->c3);	
		col2 = mergeregion(t1->c2, t1->c4);
	
	if( row1 == true )
	{
		for(int i=t1->c1->start1; i < t1->c1->start2; i++)
		{
			for(int j=t1->c1->end1; j < t1->c1->end2; j++)
			{
				if( mat[i][j] != 0)
				{
					mat[i][j] = label1;
				}
			}
		}
		//print
		/*printf("\nLocal merge ");
		for(int i=t1->c1->start1; i < t1->c1->start2; i++)
		{
			for(int j=t1->c1->end1; j < t1->c1->end2; j++)
			{
				printf("%d\t",mat[i][j]);
			}
			printf("\n");
		}	*/
		
		if( label1 > 0 )
			t1->c1->label = label1;
		t1->data = t1->c1->data;
		//printf("T1: %d" ,t1->data);
		for(int i=t1->c2->start1; i < t1->c2->start2; i++)
		{
			for(int j=t1->c2->end1; j < t1->c2->end2; j++)
			{
				if(mat[i][j] != 0)
				{
					mat[i][j] = label1;
				}
			}
		}
		//print
		/*printf("\nLocal merge ");
		for(int i=t1->c2->start1; i < t1->c2->start2; i++)
		{
			for(int j=t1->c2->end1; j < t1->c2->end2; j++)
			{
				printf("%d\t",mat[i][j]);
			}
			printf("\n");
		}	*/
		
		if( label1 > 0 )	
			t1->c2->label = label1;
		// take the data
		t1->data = t1->c2->data;
		//printf("T1: %d",t1->data);
	}
	
	if( row2 == true )
	{
		for(int i=t1->c3->start1; i < t1->c3->start2; i++)
		{
			for(int j=t1->c3->end1; j < t1->c3->end2; j++)
			{
				if(mat[i][j] != 0)
				{
					mat[i][j] = label1+1;
				}
			}
		}
		
		//print
		//cout << "\nLocal merge ";
		/*for(int i=t1->c3->start1; i < t1->c3->start2; i++)
		{
			for(int j=t1->c3->end1; j < t1->c3->end2; j++)
			{
				printf("%d\t",mat[i][j]);
			}
			printf("\n");
		}	*/

		//label1 = label1+1;
		if( label1 > 0 )	
			t1->c3->label = label1;
		t1->data = t1->c3->data;
		//printf("T1: %d",t1->data);
		for(int i=t1->c4->start1; i < t1->c4->start2; i++)
		{
			for(int j=t1->c4->end1; j < t1->c4->end2; j++)
			{
				if(mat[i][j] != 0)
				{
					mat[i][j] = label1+1;
				}
			}
		}
		

		//print
		//cout << "\nLocal merge ";
		/*for(int i=t1->c4->start1; i < t1->c4->start2; i++)
		{
			for(int j=t1->c4->end1; j < t1->c4->end2; j++)
			{
				printf("%d\t",mat[i][j]);
			}
			printf("\n");
		}	*/

		if( label1 > 0 )	
			t1->c4->label = label1;
		t1->data = t1->c4->data;
		//printf("T1: %d",t1->data);

	}
	//cout << "\tRow1 " << row1 << "\tRow2 " <<  row2 ;

	if( col1 == true )
	{
		if( row1 == true )
		{
			if( t1->c1->label > 0 )	
			{
				t1->c3->label = t1->c1->label;
				for(int i=t1->c3->start1; i < t1->c3->start2; i++)
				{	
					for(int j=t1->c3->end1; j < t1->c3->end2; j++)
					{
						if(mat[i][j] != 0)
						{
							mat[i][j] = t1->c1->label;
						}
					}
				}
			}	


			//print

			//cout << "\nLocal merge ";
			/*for(int i=t1->c3->start1; i < t1->c3->start2; i++)
			{
				for(int j=t1->c3->end1; j < t1->c3->end2; j++)
				{
					printf("%d\t",mat[i][j]);
				}
				printf("\n");
			}	*/
		
		t1->data = t1->c1->data;
		//printf("T1: %d",t1->data);
		}
		
		else
		{
			for(int i=t1->c1->start1; i < t1->c1->start2; i++)
			{
				for(int j=t1->c1->end1; j < t1->c1->end2; j++)
				{
					if(mat[i][j] != 0)
					{
						mat[i][j] = label1+1;
					}
				}
			}

			//print
			//cout << "\nLocal merge ";
		/*for(int i=t1->c1->start1; i < t1->c1->start2; i++)
		{
			for(int j=t1->c1->end1; j < t1->c1->end2; j++)
			{
				printf("%d\t",mat[i][j]);
			}
			printf("\n");
		}	*/			

			//label1 = label1+1;
			if( label1 > 0 )
				t1->c1->label = label1;
			t1->data = t1->c1->data;
			//cout << "T1: " << t1->data;
			for(int i=t1->c3->start1; i < t1->c3->start2; i++)
			{
				for(int j=t1->c3->end1; j < t1->c3->end2; j++)
				{
					if(mat[i][j] != 0)
					{
						mat[i][j] = label1+1;
					}
				}
			}
		

			//print
			//cout << "\nLocal merge ";
		/*for(int i=t1->c3->start1; i < t1->c3->start2; i++)
		{
			for(int j=t1->c3->end1; j < t1->c3->end2; j++)
			{
				printf("%d\t",mat[i][j]);
			}
			printf("\n");
		}	*/
		
			if( label1 > 0 )	
				t1->c3->label = label1;	
			t1->data = t1->c3->data;
			//printf("T1: %d" ,t1->data);
		}
	
	}
	
	if( col2 == true )
	{
		if( row2 == true )
		{
		if( t1->c2->label > 0 )	
		{
			t1->c4->label = t1->c2->label;
			for(int i=t1->c4->start1; i < t1->c4->start2; i++)
			{
				for(int j=t1->c4->end1; j < t1->c4->end2; j++)
				{
					if(mat[i][j] != 0)
					{
						mat[i][j] = t1->c2->label;
					}
				}
			}
		}
		//print
		//cout << "\nLocal merge ";
		/*for(int i=t1->c4->start1; i < t1->c4->start2; i++)
		{
			for(int j=t1->c4->end1; j < t1->c4->end2; j++)
			{
				printf("%d\t",mat[i][j]);
			}
			printf("\n");
		}	*/
		t1->data = t1->c2->data;
		//printf("T1: %d" ,t1->data);
		}
		
		else
		{
			//print
			//cout << "\nLocal merge ";
			/*for(int i=t1->c2->start1; i < t1->c2->start2; i++)
			{
				for(int j=t1->c2->end1; j < t1->c2->end2; j++)
				{
					printf("%d\t",mat[i][j]);
				}
			printf("\n");
			}	*/
	
				//label1 = label1+1;
				if( label1 > 0 )
					t1->c2->label = label1;
				t1->data = t1->c2->data;
				//printf("T1: %d",t1->data);
				for(int i=t1->c4->start1; i < t1->c4->start2; i++)
				{
					for(int j=t1->c4->end1; j < t1->c4->end2; j++)
					{
						if(mat[i][j] != 0)
						{
							mat[i][j] = label1;
						}
					}
				}

			//print
			//cout << "\nLocal merge ";
		/*for(int i=t1->c4->start1; i < t1->c4->start2; i++)
		{
			for(int j=t1->c4->end1; j < t1->c4->end2; j++)
			{
				printf("%d\t",mat[i][j]);
			}
			printf("\n");
		}	*/
		
			if( label1 > 0 )
				t1->c4->label = label1;
			t1->data = t1->c4->data;
			//printf("T1: %d",t1->data);
		}
	}
	/*printf("\nPOST\n");	
	for(int i = 0; i < m1; i++)
	{
		for(int j=0; j<m1; j++)
		{
			//mat[i][j] = mat1[m1*i + j];
			printf("%d\t",mat[i][j]);
		}
		printf("\n");
	}		*/
	for(int h =0; h < m1; h++)
			{
				for(int w =0; w < m1; w++)
				{
					mat1[m1*h + w] = mat[h][w];
					//cout << "\t " << p[m1*h + m1];
				}
				//cout << "\n";
			}
}

__host__ __device__ bool mergeregion(struct tree* t1, struct tree* t2)
{
	if(t1->data!=1 && t2->data!=1 && t1->data == t2->data)
	{ 
		cout << "\n\nMerging: T1 -> (" << t1->start1 << "\t" << t1->end1 << "),(" << t1->start2 << "\t" << t1->end2 << ")\tData " << t1->data <<"\t T2 -> (" << t2->start1 << "\t" << t2->end1 << "),(" << t2->start2 << "\t" << t2->end2 << ")\tData " << t2->data;
		return true;
	}			
	else
		return false;
}

void labelling(int *mat[],struct tree* t1,struct tree* t2)
{
	cout << "\n\nLblng: T1 -> (" << t1->start1 << "\t" << t1->end1 << "),(" << t1->start2 << "\t" << t1->end2 << ")\tData " << t1->data <<"\t T2 -> (" << t2->start1 << "\t" << t2->end1 << "),(" << t2->start2 << "\t" << t2->end2 << ")\tData " << t2->data << "  " << t2->label;
	

	for(int i=t1->start1; i < t1->start2; i++)
	{
		for(int j=t1->end1; j < t1->end2; j++)
		{
			if(mat[i][j] != 0 && t2->label > 0)
			{
				mat[i][j] = t2->label;
			}				
		}
		cout << "\n";
	}
	for(int i=t1->start1; i < t1->start2; i++)
	{
		for(int j=t1->end1; j < t1->end2; j++)
		{
			cout << "\t" << mat[i][j] ;			
		}
		cout << "\n";
	}		
	t1->label = t2->label;	
				
}
//global merge
void mergeglobe(int *mat[], struct tree* t1,struct tree* t2,struct tree* t3, struct tree* t4)
{
 // 1 -2 & 3 - 4
	if(t1!=NULL && t2!=NULL && t3!=NULL && t4!=NULL)
	{
		if(t1->fg2 == 1 && t2->fg1 == 1)
		{
			//if( t1->c2->data == t2->c1->data )
			//{
				if( t1->c2->label > t2->c1->label )
				{
					labelling( mat, t1->c2, t2->c1 );
				}
				else
				{
					labelling( mat, t2->c1, t1->c2 );	
				}
			//}		
		} 
		
		if(t1->fg4 == 1 && t2->fg3 == 1)
		{
			//if( t1->c4->data == t2->c3->data )
			//{
				if( t1->c4->label > t2->c3->label )
				{
					labelling( mat, t1->c4, t2->c3 );
				}
				else
				{
					labelling( mat, t2->c3, t1->c4 );
				}	
			//}		
		} 
		if(t3->fg2 == 1 && t4->fg1 == 1)
		{
			//if( t3->c2->data == t4->c1->data )
			//{
				if( t3->c2->label > t4->c1->label )
				{
					labelling( mat, t3->c2, t4->c1 );
				}
				else
				{
					labelling( mat, t4->c1, t3->c2 );	
				}
			//}		
		}
		if(t3->fg4 == 1 && t4->fg3 == 1)
		{
			//if( t3->c4->data == t4->c3->data )
			//{
				if( t3->c4->label > t4->c3->label )
				{
					labelling( mat, t3->c4, t4->c3 );
				}
				else
				{
					labelling( mat, t4->c3, t3->c4 );
				}	
			//}		
		}
// 3-1 & 4-2
		if(t1->fg3 == 1 && t3->fg1 == 1)
		{
			//if( t1->c3->data == t3->c1->data )
			//{
				if( t1->c3->label > t3->c1->label )
				{
					labelling( mat, t1->c3, t3->c1 );
				}
				else
				{
					labelling( mat, t3->c1, t1->c3 );	
				}
			//}		
		}
		if(t1->fg4 == 1 && t3->fg2 == 1)
		{
			//if( t1->c4->data == t3->c2->data )
			//{
				if( t1->c4->label > t3->c2->label )
				{
					labelling( mat, t1->c4, t3->c2 );
				}
				else
				{
					labelling( mat, t3->c2, t1->c4 );
				}	
			//}		
		}	
		if(t2->fg3 == 1 && t4->fg1 == 1)
		{	
			//if( t2->c3->data == t4->c1->data )
			//{
				if( t2->c3->label > t4->c1->label )
				{
					labelling( mat, t2->c3, t4->c1 );
				}
				else
				{
					labelling( mat, t4->c1, t2->c3 );	
				}
			//}		
		}
		if(t2->fg4 == 1 && t4->fg2 == 1)
		{
			//if( t2->c4->data == t4->c2->data )
			//{
				if( t2->c4->label > t4->c2->label )
				{
					labelling( mat, t2->c4, t4->c2 );
				}
				else
				{
					labelling( mat, t4->c2, t2->c4 );
				}	
			//}		
		}
		
	}						 			
}	
	
bool pred(int h1, int w1, int h,int w,int *mat[])
{
	int mean1 = mean(h1,w1,h,w,mat);
    	double var = 0; 
	int std_dev;
    	for (int a = h1; a < h; a++)
    	{
    		for (int b = w1; b < w; b++)
    		{
    			var += ((mat[a][b] - mean1) * (mat[a][b] - mean1));
    			
    		}
    	}
	int dx = h-h1;
	int dy = w-w1;
    	var /= (dx*dy);
	cout << "\nVar: " << var << "\t";
    	std_dev = sqrt(var);
	cout << "\nStddev: " << std_dev << "\t";
	return (std_dev <= 5.8) || ((dx*dy) <= 1) ;	
}

void print(struct tree* root1)
{
	 
	if(root1!=NULL)
	{
	//cout << "In: \n";
		if(root1->data!=-100 && root1->data!=1)
		{
		cout << "\nNode: (" << root1->start1 << "," << root1->end1 << ") (" << root1->start2 << "," << root1->end2 << ")" << "\tData: " << root1->data << "\tfg : " << root1->fg1 << root1->fg2 << root1->fg3 << root1->fg4;
		}
		else
		{
		
		}
		print(root1->c1);
		print(root1->c2);
		print(root1->c3);
		print(root1->c4);
	}
}


int  mean(int h1, int w1,int h,int w,int *mat[])
{
	double total = 0; int mean;
    	for (int i = h1; i < h; i++)
    	{
    		for (int j = w1; j < w; j++)
    		{
 
    			total += mat[i][j];
    		}
    	}
	int dx = h-h1;
	int dy = w-w1;
	cout << "\nTotal\t" <<total;
    	mean = (total/ (dx*dy));
	cout << "\nMean\t" << mean;
	return mean;	
}

void  process_png_file(unsigned int m1) {
 
mat=new int*[m1];
	for( int i=0;i<m1;i++)
	{
		mat[i]=new int[m1];
	}
 for(int y = 0; y < m1; y++) 
{
	for(int x = 0; x < m1; x++) 
	{
		mat[y][x]=0;
	} 
		printf("\n");
}

for(int y = 0; y < height; y++) 
{
	printf("\n");
	png_bytep row = row_pointers[y];
    	for(int x = 0; x < width; x++) 
	{
		png_bytep px = &(row[x * 4]);
      		//printf("RGB(%3d, %3d, %3d)\n",px[0], px[1], px[2]);  
      		int a = 0.72*px[0] + 0.72*px[1] + 0.72*px[2];
     		if( a > 128 )
      		{
      			mat[y][x]=a;
     		}
      		else
		{
			mat[y][x]=0;
		}
   	 }
}
printf("\nMatrix after thresholding\n");
for(int y = 0; y < m1; y++) 
{
	for(int x = 0; x < m1; x++) 
	{
		printf("%d\t",mat[y][x]);
	} 
	printf("\n");
} 

region r;
r.x1 = 0;
r.y1 = 0;
r.x4 = m1;
r.y4 = m1;

root = new tree();
struct tree *temp = new tree();
temp->start1 = r.x1;
temp->end1 = r.y1;
temp->start2 = r.x4;
temp->end2 = r.y4;
root=temp;

//Splitting :
split(r,mat,m1,temp);

//printing trees
//cout << "\nTRee before\n";
//print(root);
printf("\nMatrix after splitting \n");
for(int y = 0; y < m1; y++) 
{
	for(int x = 0; x < m1; x++) 
	{
		printf("%d\t",mat[y][x]);
	}
	printf("\n");
} 
cout << "\nLevel Order Traversal of Tree: \n" ;
printlevelorder(root,m1);

//cout << "\nTree after\n";
//print(root);
// Colour
int col = 5;
for(int y = 0; y < height; y++) 
{
    	png_bytep row = row_pointers[y];
    		for(int x = 0; x < width; x++) 
		{
			if( mat[y][x] != 0 )
			{
				png_bytep px = &(row[x * 4]);
				int mod = (mat[y][x]%5);
				if(mod == 0)
				{
					px[0]=50;
					px[1]=100;
					px[2]=150;
				}
				if(mod == 1)
				{
					px[0]=100;
					px[1]=200;
					px[2]=300;	
				}
				if(mod == 2) 
				{
					px[0]=200;
					px[1]=400;
					px[2]=600;	
				}
				if(mod == 3)
				{
					px[0]=400;
					px[1]=800;
					px[2]=1200;	
				}
				if(mod == 4)
				{
					px[0]=800;
					px[1]=1600;
					px[2]=2400;	
				}
    			}
		}
		
}
}
region split( region r ,int *mat[], unsigned int m1, struct tree *temp1)
{
//count++;

bool mean1=pred(r.x1,r.y1,r.x4,r.y4,mat);
int mean2 = mean(r.x1,r.y1,r.x4,r.y4,mat);
temp1->data = mean2;
if(mean1)
{
	
	cout << "\nLabelling (" << r.x1 << "\t" << r.y1 << ")\t(" << r.x4 << "\t" << r.y4 << ")\n" ;
	int mean2 = mean(r.x1,r.y1,r.x4,r.y4,mat);
	for( int i=r.x1; i < r.x4; i++)
	{
		for( int j=r.y1; j < r.y4; j++)
		{
			mat[i][j]=mean2;
		}
	}
	
	temp1->data = mean2;
	int p;
	for( p=0 ; p < childs.size() ; p++)
	{
		if(childs[p].x1 == r.x1 && childs[p].y1 == r.y1 && childs[p].x4 == r.x4 && childs[p].y4 == r.y4)
		{
			//cout << "\np: " << p;
			childs.erase(childs.begin() + p); 
			break;
		}
	}
}	
else
{
	count++;
	cout << "\nSplitting ("<< r.x1 << "\t" << r.y1 << ")\t(" << r.x4 << "\t" << r.y4 << ")\n" ;
	int w = ceil(m1/2);
	int h = ceil(m1/2);
	//r.size1=r.size1/2;
	region r1,r2,r3,r4;
	temp1->c1 = new tree();
	temp1->c2 = new tree();
	temp1->c3 = new tree();
	temp1->c4 = new tree();

	r1.x1 = r.x1,r1.y1 = r.y1,r1.x4 = r.x1+h,r1.y4 = r.y1+w;
	r2.x1 = r.x1,r2.y1 = r.y1+w,r2.x4 = r.x1+h,r2.y4 = r.y1+m1;
	r3.x1 = r.x1+h,r3.y1 = r.y1,r3.x4 = r.x1+m1,r3.y4 = r.y1+h;
	r4.x1 = r.x1+h,r4.y1 = r.y1+w,r4.x4 = r.x4,r4.y4 = r.y4;

	temp1->c1->start1 = r1.x1, temp1->c1->end1 = r1.y1, temp1->c1->start2 = r1.x4, temp1->c1->end2 = r1.y4;
	temp1->c2->start1 = r2.x1, temp1->c2->end1 = r2.y1, temp1->c2->start2 = r2.x4, temp1->c2->end2 = r2.y4;
	temp1->c3->start1 = r3.x1, temp1->c3->end1 = r3.y1, temp1->c3->start2 = r3.x4, temp1->c3->end2 = r3.y4;
	temp1->c4->start1 = r4.x1, temp1->c4->end1 = r4.y1, temp1->c4->start2 = r4.x4, temp1->c4->end2 = r4.y4;

	//find the means to set fg
	int m1 = mean(r1.x1,r1.y1,r1.x4,r1.y4,mat);
	int m2 = mean(r2.x1,r2.y1,r2.x4,r2.y4,mat);
	int m3 = mean(r3.x1,r3.y1,r3.x4,r3.y4,mat);
	int m4 = mean(r4.x1,r4.y1,r4.x4,r4.y4,mat);
	cout << "\nMeans : " << m1 << " " << m2 << " " << m3 << " " << m4 ;	
	if(m1 > 0)
	{
		temp1->fg1 = 1;	
	}
	if(m2 > 0)
	{
		temp1->fg2 = 1;	
	}
	if(m3 > 0)
	{
		temp1->fg3 = 1;	
	}
	if(m4 > 0)
	{
		temp1->fg4 = 1;	
	}

	childs.push_back(r1);
	childs.push_back(r2);
	childs.push_back(r3);
	childs.push_back(r4);
	/*cout << "\nVector after push : \n" ;
	cout << "\nVector size : " << childs.size() << "\n" ;
	for( int i=0 ;i < childs.size(); i++)
	{
		cout << "\t (" << childs[i].x1 << "," << childs[i].y1 << "),";
		cout << "(" << childs[i].x4 << "," << childs[i].y4 << ")";		
	}	*/
	//childs.erase(childs.begin());
	int p;
	for( p=0 ; p < childs.size() ; p++)
	{
		if(childs[p].x1 == r.x1 && childs[p].y1 == r.y1 && childs[p].x4 == r.x4 && childs[p].y4 == r.y4)
		{
			//cout << "\np: " << p;
			childs.erase(childs.begin() + p); 
			break;
		}
	}
	/*cout << "\nVector after erase : \n" ;
	for( int i=0 ;i < childs.size(); i++)
	{
		cout << "\t (" << childs[i].x1 << "," << childs[i].y1 << ")";
		cout << "(" << childs[i].x4 << "," << childs[i].y4 << ")";		
	} */
	r1=split(r1,mat,w,temp1->c1);
	r2=split(r2,mat,w,temp1->c2);
	r3=split(r3,mat,w,temp1->c3);
	r4=split(r4,mat,w,temp1->c4);
	
} 

/*cout << "\nVector size : " << childs.size() << "\n" ;
cout << "FG : " << temp1->fg1 << " " << temp1->fg2 << " " << temp1->fg3 << " " << temp1->fg4; */
}



int main(int argc, char *argv[]) {
  if(argc != 3) abort();
  		clock_t begin,end;
		double time_spent;
		begin=clock();
unsigned int m = read_png_file(argv[1]);
  cout << "\nM: " << m;
  process_png_file(m);
  write_png_file(argv[2]);
  cout<<"\n\nNo. of splits:\t"<<count;
  		end=clock();
		time_spent=(double)(end-begin)/CLOCKS_PER_SEC;
		printf("\nTIME : %lf",time_spent);
  cout<<"\nVector size:\n"<<childs.size();
  cout << "\nVector final: \n" ;
	for( int i=0 ;i < childs.size(); i++)
	{
		cout << "\t (" << childs[i].x1 << "," << childs[i].y1 << ")";
		cout << "(" << childs[i].x4 << "," << childs[i].y4 << ")";		
	}
	cout << "\nFINALE: ";
			for(int i = 0; i < m; i++)
			{
				for(int j=0; j<m; j++)
				{
					//mat[i][j] = mat1[m1*i + j];
					printf("%d\t",mat[i][j]);
				}
				printf("\n");
			}
  return 0;
}
