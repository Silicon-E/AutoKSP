#define _USE_MATH_DEFINES
#include <cmath>
#include <vector>
#include <iostream>
#include <stdio.h>
#include <string>
#include <array>
#include <random>
#include <fstream>


//0: uniform, 1: full aneal, 2: linear, 3: 3-point plus 1 dip, 4: 3 and then 1
#define MODE 3
//mode 4 seems to be useless
#define NONLINEAR true

const double G = 9.8;
const double std_vsp1 = G * 295.;
const double std_vsp2 = G * 340.;
const double std_acc1 = G * 3.;
const double std_drag_1 = G * 340.;

const double vterm_gees = 2.0; // number of gs of terminal velocity increase rate at hterm (shoud be about 2)
const double vterm_typical = 250.0;//wrong but gives good approx for hterm
const double vterm_actual = 400.0;
const double th_term = M_PI/4.0;

double max_tries(int segments, double dthrel) {
    return 20 + 5 / std::sqrt(dthrel);
    //return 50 + 20 / std::sqrt(dthrel);
}

class Planet{
public:
    double asl_press;
    double atm_hte;
    double atm_rare_h; // height at when to allow negative v_y if needed
    double atm_total_h; // height to space
    double radius;
    double mu;
    double rotvel;
    bool has_atm;
    bool oxygen;
    double tpc_atm_burn_ratio;
    Planet(double radius, double mu,double rotvel, double asl_press, double atm_hte,double atm_rare_h,double atm_total_h, bool has_atm, bool oxygen,double tpc_atm_burn_ratio):
        radius(radius), mu(mu),rotvel(rotvel), asl_press(asl_press),atm_hte(atm_hte),atm_rare_h(atm_rare_h),atm_total_h(atm_total_h),has_atm(has_atm),oxygen(oxygen),tpc_atm_burn_ratio(tpc_atm_burn_ratio) 
    {
        
        //std::cout << "wmg = " << this->rotvel<< "\n";
        //std::cout << "rotvel(0) = " << this->rotation_velocity(0) << "\n";
    }
    
    double g(double alt) const {
        return mu / (radius+alt)/(radius+alt);
    }
    double vc(double alt) const {return std::sqrt(mu/(radius+alt));}
    double get_hterm_typical() const {
        //should be near 10 000 for kerbin
        static double iv = std::sqrt(vterm_gees * 2.0 * atm_hte * g(0)); //zeroth order
        //std::cout << "iv = " << vterm_gees << "," << atm_hte << "," << g(0) << "\n";
        //std::cout << "iv = " << iv << "\n";
        static double hterm = 2.0 * atm_hte * (std::log(iv/vterm_typical ) + 0.5 * std::log(asl_press/tpc_atm_burn_ratio));
        return hterm;
    }
    double get_initial_velocity () const {
        static double h = get_hterm_typical();//first order correction
        static double vinit = std::sqrt(vterm_gees * 2.0 * atm_hte * g(h));
        return vinit;
    }
    double rotation_velocity(double alt) const {
        return (radius+ alt) * rotvel;
    }

};
const Planet KERBIN(600000.0,G * 600000 * 600000,2. * M_PI / 3600./5.,1.0,5775.,55000.,70000.,true,true, std::exp(-1000.0/std_vsp1));
const Planet UNIT_SPHERE(1,1,0,0,1,0,0,false,false, 1);

class Rocket {
public:
    double stage1_drag; // f = m_0 * v^2 * drag * p
    double stage2_drag;

    double stage1_extra_dv;
    double stage1_vsp_vac;
    double stage1_tsp; // this is tsp remaining when at turn height
    double stage1_loss_frac_per_atm;
    
    double stage2_dv; // should not be used
    double stage2_vsp_vac;
    double stage2_tsp;
    double stage2_loss_frac_per_atm;
    Rocket(double stage1_drag,double stage2_drag, 
        double stage1_extra_dv, double stage1_vsp_vac,double stage1_tsp, double stage1_loss_frac_per_atm,
        double stage2_dv, double stage2_vsp_vac,double stage2_tsp, double stage2_loss_frac_per_atm): 
        stage1_drag(stage1_drag), stage2_drag(stage2_drag),
        stage1_extra_dv(stage1_extra_dv),stage1_vsp_vac(stage1_vsp_vac), stage1_tsp(stage1_tsp), stage1_loss_frac_per_atm(stage1_loss_frac_per_atm),
        stage2_dv(stage2_dv),stage2_vsp_vac(stage2_vsp_vac), stage2_tsp(stage2_tsp), stage2_loss_frac_per_atm(stage2_loss_frac_per_atm)
    {}
    double get_tf(double extra_dv) const {
        using namespace std;
        return stage1_tsp * (1.-exp(-stage1_extra_dv/stage1_vsp_vac))
            +stage2_tsp * (1.-exp(-(stage2_dv-extra_dv)/stage2_vsp_vac));
    }
    double get_t1() const {
        using namespace std;
        return stage1_tsp * (1.-exp(-stage1_extra_dv/stage1_vsp_vac));
    }
    double get_t2() const {
        using namespace std;
        return 
            stage2_tsp * (1.-exp(-(stage2_dv)/stage2_vsp_vac));
    }
    static Rocket typical(double extra_dv_first_stage, double stage_2_twr) {
        double drag1 =9.8 / vterm_actual/ vterm_actual;
        double drag2 = drag1 / 2.0; // reasonable
        return Rocket(drag1,drag2,
           extra_dv_first_stage   , std_vsp1, std_vsp1 / std_acc1,0.1,
           3000.0 - extra_dv_first_stage  , std_vsp2, std_vsp2 / stage_2_twr / G,0.7);
    }
    static Rocket typical_nuclear(double extra_dv_first_stage, double stage_2_twr) {
        double drag1 =9.8 / vterm_actual/ vterm_actual;
        double drag2 = drag1 / 2.0;
        return Rocket(drag1,drag2,
           extra_dv_first_stage   , std_vsp1, std_vsp1 / std_acc1,0.1,
           4000.0 - extra_dv_first_stage  , G*800.0, G*800.0 / stage_2_twr / G,0.8);
    }
};
class Orbit2D {
public:
    double e,a;
    double argpe; // relative to initial; ry
    double L;
    const Planet& body;

    Orbit2D(double r, double vx, double vy, const Planet& body): body(body)
    {
        //DO NOT USE; THIS IS BROKEN
        using namespace std;
        //from my TI-84+
        double g = body.mu / r / r;
        double vsq = vx*vx+vy*vy;
        double arg,e,ea;
        //double e1 = - (vx * r) / sqrt(r *r *  (vx*vx+vy*vy));
        //double f1 =  (vy * r) / sqrt(r *r *  (vx*vx+vy*vy));
        double e1 = - (vx ) / sqrt(  vsq);
        double f1 =  (vy ) / sqrt(  vsq);
        //double t1 = atan2(vy,vx) - atan2(vx,vy);
        double t1 = 2 * atan2(vx,-vy); // angle of other focus from object
        if (vsq == 2 * body.mu / r) {
            //parabola
            double s = r * (1 - cos(t1 - M_PI/2.0 ))/ 2.0;
            e = 1;
            a=INFINITY;
            argpe=-t1;
        } else {
            //double l1 = r * vsq / (vsq - 2 *g* abs(e1) * r);//this one is wrong
            double l1 = -abs(e1) * r * vsq / (vsq - 2 *g * r);
            double i1 = l1 * cos(t1);
            double j1 = r + l1 * sin(t1);
            double s1 = (l1 + r)/2.0;
            arg = atan2(-j1,-i1); // TODO debug here
            a= (l1 + r)/ 2.0;
            ea = hypot(l1 * cos(t1), r + l1 * sin(t1))/2.0; // e * a
        }
        this-> a = a;
        this -> e = ea / a;
        this -> argpe = arg;
        this -> L = r * vx;
    }
    friend std::ostream& operator << (std::ostream& out, const Orbit2D& orbit);
};
std::ostream& operator << (std::ostream& out, const Orbit2D& orbit){
    char buff[1024];
    std::sprintf(buff, "Orbit( a= %e ,e= %e ,argpe= %e  ,L= %e )",orbit.a,orbit.e,orbit.argpe,orbit.L);
    out << std::string(buff);
    return out;
}
double toRad(double deg) {return M_PI/180.0 * deg;}
double toDeg(double rad) {return 180.0/M_PI * rad;}


typedef std::array<double,3> HV;
HV add(HV a,HV b){ return {a[0]+b[0],a[1]+b[1],a[2]+b[2]};}
HV mult(HV a,double b){ return {a[0]*b,a[1]*b,a[2]*b};}
HV ddt (HV hv, double th, double acc, const Planet& planet, double dragfac){
    //d/dt
    using namespace std;
    double h = hv[0], vx=hv[1], vy = hv[2];
    double dh = vy;
    double v = hypot(hv[1],hv[2]);
    double vrotx = planet.rotation_velocity(h);
    //prograde equitorial
    //can adjust deltav-1 on KOS end
    double v_airx = hv[1]-vrotx;
    double v_air = hypot(v_airx,hv[2]);
    double drag = dragfac * planet.g(planet.get_hterm_typical()) * 
        (v_air*v_air)/planet.get_initial_velocity()/planet.get_initial_velocity() 
        *exp(-(h - planet.get_hterm_typical())/planet.atm_hte);
    double dvx =  acc * cos(th)  - vx*vy /(planet.radius+ h)               - drag * v_airx / v_air;
    double dvy =  acc * sin(th)  + vx*vx /(planet.radius+ h) - planet.g(h) - drag * hv[2] / v_air;

    return {dh,dvx,dvy};
}
HV RK4 (HV hv, double th, double acc, const Planet& planet, double dragfac, double dt){
    //d/dt
    HV dhv1 = ddt(hv,th,acc,planet,dragfac);
    HV dhv2 = ddt(add(hv,mult(dhv1,dt/2.0)),th,acc,planet,dragfac);
    HV dhv3 = ddt(add(hv,mult(dhv2,dt/2.0)),th,acc,planet,dragfac);
    HV dhv4 = ddt(add(hv,mult(dhv3,dt)),th,acc,planet,dragfac);

    HV dhv = mult(add(add(dhv1,dhv4),mult(add(dhv2,dhv3),2.0)),1.0/6.0);
    return add(hv,mult(dhv,dt));
}
int integrate(double& ddv, Planet planet, Rocket rocket, std::vector<double>& angles, std::vector<double>& deltaVs, std::vector<double>& dts, int segments, int segments1, double hnot, double vnot,
                bool print = false, HV* hvf = nullptr){
    using namespace std;
    HV hv = {hnot,vnot * cos(th_term) + planet.rotation_velocity(hnot),  vnot * cos(th_term)};
    double cdv = 0;
    double dragc=1.0;
    for(int i=0;i<segments;i++){
        if(i==segments1){
            dragc = rocket.stage2_drag/ rocket.stage1_drag;
            cdv=0;
        }
        double acc = deltaVs[i] / dts[i];
        double dragfac =  dragc*exp(cdv / rocket.stage1_vsp_vac) ;
        if(print) cout << "hv = " << hv[0] << " , " << hv[1] << " , " << hv[2] << "\n";
        hv = RK4(hv,angles[i],acc,planet,dragfac,dts[i]);
        if(hv[2] < 0 && hv[0] < planet.atm_rare_h){
            //too low
            ddv = -1.0;
            return -1;
        }else if ((hv[1]-planet.rotation_velocity(hv[0]))/vnot > exp((hv[0]-hnot)/planet.atm_hte/2.0)){
            //also too low and fast
            ddv = -1.0;
                return -1;
        }else if (hypot(hv[1],0) > planet.vc(hv[0])) {
            //done early?
            double hmax = hv[0] + hv[2] * (planet.radius+hv[0]) / (planet.vc(hv[0]));
            if (hmax > planet.atm_total_h){
                ddv = hypot(hv[1],0) - planet.vc(hv[0]);
                for(int j=i+1;j<segments;j++){
                    ddv += deltaVs[j];
                } 
                if(hvf != nullptr) *hvf = hv;
                return i;// success > 0
            }else {
                ddv = -1.0;
                return -2;
            }
        }
        cdv += deltaVs[i];

    }
    ddv =  hypot(hv[1],0) - planet.vc(hv[0]);
    return -3;
}
double randMToN(double M, double N)
{
    return M + (rand() / ( RAND_MAX / (N-M) ) ) ;  
}
class Curve {
        public:
        double in,m,f,d1,d2;
        Curve(double theta): in(theta),m(theta),f(theta),d1(0),d2(0) {}
        Curve(double i,double m,double f, double d1, double d2): in(i),m(m),f(f),d1(d1),d2(d2) {}
        void populate (std::vector<double>& thetas, int segments, int segments1){
            for (int i=0;i<segments1;i++){
            double a = (double ) i / (double) segments1;
            thetas[i]=in * (1.-a) + m * a + a * (1.-a) * d1;
            }for (int i=segments1;i<segments;i++){
                double a = (double ) (i-segments1) / (double) (segments-segments1);
                thetas[i]=m * (1.-a) + f * a + a * (1.-a) * d2;
            }
        }
        double getAt(double time,double t1,double t2){
            if(time<=t1){
                double a = time/t1;
                return in * (1.-a) + m * a + a * (1.-a) * d1;
            }else {
                double a = (time-t1)/t2;
                return m * (1.-a) + f * a + a * (1.-a) * d2;
            }
        }
        std::ostream& printToKos(double ddv,std::ostream& fout) const{
            fout << "list(" 
                << toDeg(in) << " , "
                << toDeg(m) << " , "
                << toDeg(f) << " , "
                << toDeg(d1) << " , "
                << toDeg(d2) << " , "
                << ddv <<     ")";
            return fout;
        }
        Curve operator + (const Curve& c) const {
            return Curve(this->in+c.in, this->m+c.m,this->f+c.f,this->d1+c.d1,this->d2+c.d2);
        }
        Curve operator - (const Curve& c) const {
            return Curve(this->in-c.in, this->m-c.m,this->f-c.f,this->d1-c.d1,this->d2-c.d2);
        }
        friend std::ostream&  operator << (std::ostream& out, const Curve& c);
};
std::ostream&  operator << (std::ostream& out, const Curve& c){
    out << "Curve(" << c.in << " , "<< c.m << " , "<< c.f << " , "<< c.d1 << " , "<< c.d2 << " ) ";
    return out;
}
int aneal(Planet planet, Rocket rocket, Curve* curveref = nullptr,bool out=false, double* tf = nullptr, double* ddvp = nullptr){
    using namespace std;
    vector<double> angles;
    vector<double> deltaVs;
    vector<double> dts;
    int segments = 50;
    double time1 = rocket.stage1_tsp * (1-exp(-rocket.stage1_extra_dv/rocket.stage1_vsp_vac));
    double time2 = rocket.stage2_tsp * (1-exp(-rocket.stage2_dv/rocket.stage2_vsp_vac));
    //equal time
    int segments1 = round(time1/(time1+time2) * (double) segments);
    if (segments1 < 1) segments1 = 1;
    if (segments1 >= segments) segments1 = segments-1;
    double dt1 = time1 / (double)segments1;
    double dt2 = time2 / (double)(segments-segments1);
    for (int i=0;i<segments1;i++){
        deltaVs.push_back(rocket.stage1_vsp_vac * log((rocket.stage1_tsp-dt1*(double)i)/(rocket.stage1_tsp-dt1*(double)(i+1))));
        angles.push_back(M_PI/4.0);
        dts.push_back(dt1);
    }
    for (int i=0;i<segments-segments1;i++){
        deltaVs.push_back(rocket.stage2_vsp_vac * log((rocket.stage2_tsp-dt2*(double)i)/(rocket.stage2_tsp-dt2*(double)(i+1))));
        angles.push_back(M_PI/4.0);
        dts.push_back(dt2);
    }
    double vnot = planet.get_initial_velocity();
    double hnot = planet.get_hterm_typical();
    if(out)cout << "vnot, hnot = " << vnot << " , " << hnot <<  "\n";

    double dDtV=0;
    int flag = integrate(dDtV,planet,rocket,angles,deltaVs,dts,segments,segments1,hnot,vnot);
    vector<double> deg30 = angles;
    for(int i=0;i<segments;i++)deg30[i] = M_PI/6.0;
    double dDtV2=0;
    int flag2 = integrate(dDtV2,planet,rocket,deg30,deltaVs,dts,segments,segments1,hnot,vnot);
    double ddv = dDtV;
    if(flag<0){
        if(flag2<0){
            if(out)cout<<"stages too weak" << dDtV<< ", " << dDtV2 << "\n";
            return -1;
        } else {
            angles = deg30;
            ddv=dDtV2;
        }

    } else if (flag2>=0) {
            angles = deg30;
            ddv=dDtV2;
    }
    double dth=0.05; // ~3deg
    #if MODE == 0
        cout << "initially uniform "<< angles[0] << "  by , " << ddv << "  dth = "<< dth <<"\n";
    while(dth > 0.001){
        vector<double> anp = angles;
        vector<double> anm = angles;
        for (int i=0;i<segments;i++){
            anp[i]+=dth;
            anm[i]-=dth;
        }
        double plus, plusf = integrate(plus,planet,rocket,anp,deltaVs,dts,segments,segments1,hnot,vnot);
        double minus,minusf = integrate(minus, planet,rocket,anm,deltaVs,dts,segments,segments1,hnot,vnot);
        int n=0;
        if(out)cout << ":: "<< plus << "   , " << minus << ", "<< ddv <<"\n";
        if (plusf<0 && minusf < 0 || max(plus,minus) <= ddv){
            if(out)cout << "shrinking dth\n";
            dth *=0.8;
        } else if (plus > minus){
            if(out)cout << "grow th\n";
            angles = anp;
            n=plusf;
            ddv = plus;

        }else {
            if(out)cout << "decrease th\n";
            angles = anm;
            n=minusf;
            ddv = minus;
        }
        if(out)cout << "uniform "<< angles[0] << "  by , " << ddv << "dth = "<< dth <<"\n";

        if(n>=0){
            //return 0;
        }
    }
    #endif
    
    double dthnot; // ~2deg
    double dthf; // small
    int trys;
    #if MODE == 3 || MODE == 4
    
    dthnot=0.03; // ~2deg
    dthf=0.001; // small
    dth = dthnot; // k-dependant dth
        //if(out)cout << "initially uniform "<< angles[0] << "  by , " << ddv << "  dth = "<< dth <<"\n";
    trys = 0;

    Curve theta(angles[0]);
    while(dth > dthf){
        vector<double> anp = angles;
        vector<double> anm = angles;
        vector<double> dthts(angles.size(),0.0);
        vector<double> dthk(angles.size(),0.0);
        double amp = dth;
        double dthav = randMToN(-amp,amp);
        Curve dcurv(dthav + randMToN(-amp,amp)
            ,dthav + randMToN(-amp,amp)
            ,dthav + randMToN(-amp,amp)
            ,randMToN(-amp,amp)
            ,randMToN(-amp,amp));

        Curve curve_p = theta + dcurv;
        curve_p.populate(anp,segments,segments1);
        Curve curve_m = theta - dcurv;
        curve_m.populate(anm,segments,segments1);
        double plus, plusf = integrate(plus,planet,rocket,anp,deltaVs,dts,segments,segments1,hnot,vnot);
        double minus,minusf = integrate(minus, planet,rocket,anm,deltaVs,dts,segments,segments1,hnot,vnot);
        int n=0;
        //cout << ":: "<< plus << "   , " << minus << ", "<< ddv <<"\n";
        if (plusf<0 && minusf < 0 || max(plus,minus) <= ddv){
            trys++;
            if(trys>max_tries(segments,dth/dthnot) * 10){
                trys=0;
                if(out)cout  << "th+0 = " << anp[0] << "\t"
                    << "ddv = " << ddv<<"\r";
                dth *=0.8;
            }
        } else if (plus > minus){
            //cout << "grow th\n";
            angles = anp;
            theta = curve_p;
            n=plusf;
            ddv = plus;
            trys=0;

        }else {
            //cout << "decrease th\n";
            angles = anm;
            theta = curve_m;
            n=minusf;
            ddv = minus;
            trys=0;
        }
        #if false
        if(out)cout << "thetas: ";
        for (int i=0;i<segments;i++){
            if(out)cout << angles[i] << "\t";
        }
        if(out)cout << ";\n  by , " << ddv << "dth = "<< dth <<"\n";

        if(n>=0){
            //return 0;
        }
        #endif
    }
    if(out)cout << "\n";
    if(out)cout << theta << "\n";
    if(curveref!=nullptr) *curveref = theta;//retrieve curve
    #endif
    #if MODE == 1 || MODE == 2 || MODE == 4
    dthnot=0.03; // ~2deg
    dthf=0.001; // small
    dth = dthnot; // k-dependant dth
        //cout << "initially uniform "<< angles[0] << "  by , " << ddv << "  dth = "<< dth <<"\n";
    trys = 0;
    while(dth > dthf){
        vector<double> anp = angles;
        vector<double> anm = angles;
        vector<double> dthts(angles.size(),0.0);
        vector<double> dthk(angles.size(),0.0);
        double amp = dth;
        double tk1 = randMToN(-amp,amp);
        double tk2 = randMToN(-amp,amp);
        for (int i=0;i<segments;i++){
            anp[i]+=tk1 + tk2 * ((double)i-0.5*(double)segments)/(double)(segments);
            anm[i]-=tk1 + tk2 * ((double)i-0.5*(double)segments)/(double)(segments);
        }
        #if MODE == 2
        //this section only saves a few m/s typically
        for(int k=1;k< segments/2;k++) {
            amp = dth / (1.+(double)(k*k)* dth / dthnot);
            tk1 = randMToN(-amp,amp);
            for (int i=0;i<segments;i++){
                anp[i]+=tk1 * sin(M_PI * (double)(i*k)/(double)(segments));
                anm[i]-=tk1 * sin(M_PI * (double)(i*k)/(double)(segments));
        }}
        #endif
        double plus, plusf = integrate(plus,planet,rocket,anp,deltaVs,dts,segments,segments1,hnot,vnot);
        double minus,minusf = integrate(minus, planet,rocket,anm,deltaVs,dts,segments,segments1,hnot,vnot);
        int n=0;
        //cout << ":: "<< plus << "   , " << minus << ", "<< ddv <<"\n";
        if (plusf<0 && minusf < 0 || max(plus,minus) <= ddv){
            trys++;
            if(trys>max_tries(segments,dth/dthnot)){
                trys=0;
                if(out)cout << "ddv = " << ddv<<"\r";
                dth *=0.8;
            }
        } else if (plus > minus){
            //cout << "grow th\n";
            angles = anp;
            n=plusf;
            ddv = plus;
            trys=0;

        }else {
            //cout << "decrease th\n";
            angles = anm;
            n=minusf;
            ddv = minus;
            trys=0;
        }
        #if false
        if(out)cout << "thetas: ";
        for (int i=0;i<segments;i++){
            cout << angles[i] << "\t";
        }
        if(out)cout << ";\n  by , " << ddv << "dth = "<< dth <<"\n";

        if(n>=0){
            //return 0;
        }
        #endif
    }
    #endif

    HV hvf;
    if(out)cout << "\n"; 
    int fsegments = integrate(ddv,planet,rocket,angles,deltaVs,dts,segments,segments1,hnot,vnot,out, &hvf);

    #if false
    cout << "thetas: ";
    for (int i=0;i<fsegments;i++){
        cout << angles[i] << "\t";
    }
    cout  << ";\n";
    #endif
    
    if(tf!=nullptr) *tf = rocket.get_tf(ddv);//retrieve curve
    if(ddvp!=nullptr) *ddvp = ddv;
    if(out){
        ofstream fout("./data1.dat");
        fout << "# segments (1st / tot) = " << segments1 << " / " << fsegments 
        << "\t; dt1 = " << dt1 << "\t;dt2 = " << dt2 
        << "\t hvf = " << hvf[0] << " , " << hvf[1] << " , " << hvf[2] << " ; "
        << "\n";
        double cdv = 0.0;
        double time = 0.0;
        //cout << "fsegments = " << fsegments << "\n";
        for (int i=0;i<fsegments;i++){
            //frontpoint rule
            fout 
            << time << "\t"
            << cdv //+ deltaVs[i]/2.0 
            << "\t" 
            << angles[i] << "\n";
            cdv += deltaVs[i];
            time += i<segments1 ? dt1 : dt2;
        }
        fout.close();
    }
    
    return 0;
}
std::vector<double> arrange(double start,double stop,double diff=1.0){
    using namespace std;
    int size = (start-stop)/diff+1;if(size<0)size=0;
    vector<double> ret;ret.reserve(size);
    double x = start;
    while((x-stop)/diff <0){
        ret.push_back(x);
        x+=diff;
    }
    return ret;
}
std::ostream& printListKos(std::ostream& out, std::vector<double> list){
    out << "list(";
    for(int i=0;i<list.size();i++) {
        if(i>0) out << ","; else out << "";
        out << list[i];
    }
    out << ")";
    return out;

}
void export_data (){
    //write a .ks file that defines a 3d list index acording to [dv1][twr][curve-field / empty list if null]
    //also give axis data, 

    //curve args: (the 5 fields) , ddv,
    //curves are relative to full dv2 so print dv1 + dv2 = ...
    //t1 = const = twr1 * (1-e^-...)
    //same for t2
    using namespace std;
    vector<double> deltav1s = {500.0,600.0,800.0,1000,1200,1500,1800};
    vector<double> twrs = {0.3,0.4,0.5,0.6,0.7,0.8};
    Rocket rp1=Rocket::typical(0,0);
    string none = "\"None\"";
    //default build task runs in cwd ${fileDirname} (innermost folder)
    //so does default execute task
    ofstream fout("./../../generated/lib_launch/lob_data_kerbin.ks");
    //fout axis data & twr1, vsp1, vsp2, dv1+dv2
    fout << "global lib_launch_dv1s is ";
        printListKos(fout,deltav1s) << ".\n";
    fout << "global lib_launch_twr2s is ";
        printListKos(fout,twrs) << ".\n";
    fout << "global lib_launch_typicals is list("
        << std_acc1 / G << ","
        << rp1.stage1_vsp_vac << ","
        << rp1.stage2_vsp_vac << ","
        << rp1.stage1_extra_dv + rp1.stage2_dv
        <<").// twr1, vsp1, vsp2, dv1+dv2\n";
    fout << "//indexing: [index of dv1 from ~10km][index of twr2][index curve part and/or ddv]\n";
    fout << "//axis curve(in, m, f, d1, d2), ddv\n";
    fout << "global "<<"lib_launch_lob_data"<<" is list(\n";
    for(int i=0;i<deltav1s.size();i++) {
        double dv1 = deltav1s[i];
        if(i>0) fout << "\t,"; else fout << "\t ";
        fout << "list (\n";
        for(int j=0;j<twrs.size();j++){
            double twr = twrs[j];
            Rocket r=Rocket::typical(dv1,twr);
            Curve c(0,0,0,0,0);
            double tf,ddv;
            int success = aneal(KERBIN,r,&c,false,&tf,&ddv);
            //TODO print to file
            if(j>0) fout << "\t\t,"; else fout << "\t\t ";
            if(success==0) c.printToKos(ddv,fout) ;
            else fout << none;
            fout << "\n";
            cout << "progress: " << (i*twrs.size() + j) << " / " << twrs.size() * deltav1s.size() << " ;\r"; 
        }
        fout << "\t )\n";
    }
    fout << " ).\n";
    cout << "\n"; 
    fout.close();
}
void plot_twr(){
    using namespace std;
    double dv1 = 1000;
    ofstream fout("./data2.dat");
    vector<double> twrs = {0.3,0.4,0.5,0.6,0.7,0.8};
    for(int i=0;i<twrs.size();i++){
        double twr=twrs[i];
        Rocket r = Rocket::typical(dv1,twr);
        Curve c(0,0,0,0,0);
        double tf;
        int success = aneal(KERBIN,r,&c,false,&tf);
        double t1= r.get_t1(),t2 = r.get_t2();//TODO
        //cout << "t_f = " << tf << "\n";
        vector<double> ts = arrange(0,tf,tf/20.);
        for(double t: ts){
            //cout <<t << "\t";
            fout << t << "\t"<<toDeg(c.getAt(t,t1,t2)) << "\t" << twr << "\n";
        }
        //return;
        cout << "progress: " << i << " / " + twrs.size() << " ;\r"; 
    }
    cout << "\n"; 
    fout.close();
}
void plot_dv1s(){
    using namespace std;
    ofstream fout("./data2.dat");
    vector<double> deltav1s = {500,750,1000,1500};
    double twr = 0.6;
    for(int i=0;i<deltav1s.size();i++){
        double dv1=deltav1s[i];
        Rocket r = Rocket::typical(dv1,twr);
        Curve c(0,0,0,0,0);
        double tf;
        int success = aneal(KERBIN,r,&c,false,&tf);
        double t1= r.get_t1(),t2 = r.get_t2();//TODO
        //cout << "t_f = " << tf << "\n";
        vector<double> ts = arrange(0,tf,tf/20.);
        for(double t: ts){
            //cout <<t << "\t";
            fout << t << "\t"<<toDeg(c.getAt(t,t1,t2)) << "\t" << dv1 << "\n";
        }
        //return;
        cout << "progress: " << i << " / " + deltav1s.size() << " ;\r"; 
    }
    cout << "\n"; 
    fout.close();
}

int main () {
    using namespace std;
    //Orbit2D o1(1,1,-0.5,UNIT_SPHERE);
    //cout << "o1 = " << o1;
    //Rocket r = Rocket::typical(1000,0.7);
    //Rocket r = Rocket::typical(500,0.9);
    //Rocket r = Rocket::typical(1500,0.5);
    //cout << KERBIN.vc(110000) << "\n";
    //aneal(KERBIN,r,nullptr,true);
    //plot_twr();
    //plot_dv1s();
    export_data();
    return 0;
}
