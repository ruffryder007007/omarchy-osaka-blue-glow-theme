#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>
#include <vector>
// Render subtle periodic atmosphere over the original artwork. No camera movement.
int main(int argc, char** argv) {
  if(argc != 3) { std::cerr << "Usage: animate BASE.rgb SKY.gray > frames.rgb\n"; return 1; }
  const int w=1672,h=940, fps=24, seconds=32;
  const double pi=3.141592653589793;
  std::vector<unsigned char> base(w*h*3), mask(w*h), frame(w*h*3);
  std::ifstream baseFile(argv[1],std::ios::binary);
  if(!baseFile.read((char*)base.data(),base.size())) { std::cerr << "Invalid base image\n"; return 1; }
  std::ifstream maskFile(argv[2],std::ios::binary);
  if(!maskFile.read((char*)mask.data(),mask.size())) { std::cerr << "Invalid sky mask\n"; return 1; }
  auto gauss=[](double v) { return std::exp(-v*v/2); };
  // Two distant house windows and one sputtering distant street lamp.
  std::vector<double> win1(w*h),win2(w*h),lamp(w*h);
  for(int y=0;y<h;y++) for(int x=0;x<w;x++) {
    win1[y*w+x]=gauss((x-1080)/5.5)*gauss((y-573)/12.0);
    win2[y*w+x]=gauss((x-1394)/5.0)*gauss((y-456)/16.0);
    double lx=(x-1039)/7.0, ly=(y-611)/9.0;
    double core=.995*std::exp(-.5*(lx*lx*lx*lx+ly*ly*ly*ly));
    double halo=.78*gauss((x-1039)/15.0)*gauss((y-611)/17.0);
    // The lamp's blue pool and elongated reflection on the paving
    // use the exact same on/off timing as the bulb.
    double streetPool=.92*gauss((x-1060)/31.0)*gauss((y-701)/12.0);
    double streetReflection=.94*gauss((x-1050)/15.0)*gauss((y-729)/29.0);
    double groundFade=std::clamp((y-687)/10.0,0.0,1.0);
    double street=std::max(streetPool,streetReflection)*groundFade;
    lamp[y*w+x]=std::max({core,halo,street});
  }
  for(int f=0;f<fps*seconds;f++) {
    double phase=2*pi*f/(fps*seconds);
    // Brief, soft dips, each repeated only once per seamless loop.
    double flick1=.52*std::pow((1+std::cos(phase-1.8))/2,120)
                +.27*std::pow((1+std::cos(phase-2.04))/2,220);
    double flick2=.46*std::pow((1+std::cos(phase-4.5))/2,160);
    // Three irregular, fast on/off bursts at 6s, 15s and 25s.
    double lampOff=0;
    for(int start : {144,360,600}) {
      int k=f-start;
      if(k==0 || k==1 || k==3 || k==4 || k==7 || k==8 || k==9 || k==12 || k==13)
        lampOff=1;
    }
    frame=base;
    // Half-resolution atmosphere, upsampled to keep rendering economical.
    for(int y=0;y<h;y+=2) for(int x=0;x<w;x+=2) {
      int idx=y*w+x;
      if(mask[idx]==0 && win1[idx]<.001 && win2[idx]<.001 && lamp[idx]<.001) continue;
      double wave=.50+.22*std::sin(x*.018+y*.025-phase)
                    +.16*std::sin(x*.035-y*.041-2*phase+.8)
                    +.09*std::sin(x*.069+y*.057-3*phase+1.7);
      wave=std::clamp(wave,0.0,1.0);
      double mist=.38*gauss((y-(353+12*std::sin(x*.008-phase)))/42.0)*wave;
      double cloud=.20*gauss((y-(223+17*std::sin(x*.006-phase)))/28.0)*wave;
      double high=.07*gauss((y-99)/36.0)*wave;
      double alpha=(mist+cloud+high)*mask[idx]/255.0;
      double dim=(1-flick1*win1[idx]-flick2*win2[idx])*(1-lampOff*lamp[idx]);
      const double fog[3]={32,72,108};
      for(int dy=0;dy<2 && y+dy<h;dy++) for(int dx=0;dx<2 && x+dx<w;dx++) {
        int p=((y+dy)*w+x+dx)*3;
        for(int c=0;c<3;c++) frame[p+c]=std::clamp((base[p+c]*(1-alpha)+fog[c]*alpha)*dim,0.0,255.0);
      }
    }
    std::cout.write((char*)frame.data(),frame.size());
    if(f%96==0) std::cerr << "Rendered " << f/fps << "/32 seconds\n";
  }
}
