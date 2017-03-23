//
//  ViewController.m
//  GemCustomMap
//
//  Created by GemShi on 2017/3/20.
//  Copyright © 2017年 GemShi. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>

@interface ViewController ()<MKMapViewDelegate>
@property(nonatomic,strong)MKMapView *mapView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //创建地图
    self.mapView = [[MKMapView alloc]initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.userTrackingMode = YES;
    [self.view addSubview:_mapView];
    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);//设置比例
    CLLocationCoordinate2D coordinate = {39.908,116.4};//设置显示中心
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
    [self.mapView setRegion:region];
    
    //点击获取位置
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToGetLocation:)];
    [self.mapView addGestureRecognizer:tap];
    
    //路径规划
    [self programRoute];
    
    //搜索
    [self mapSearch];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 点击坐标获取地理位置
-(void)tapToGetLocation:(UITapGestureRecognizer *)tap
{
    //获取手指点击mapView的点
    CGPoint point = [tap locationInView:self.mapView];
    //将点击点转化为经纬度
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    //创建地理对象
    CLLocation *location = [[CLLocation alloc]initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    //地理编码
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if (placemarks.count == 0 || error) {
            return ;
        }
        //获取地址信息
        CLPlacemark *pm = [placemarks firstObject];
        NSLog(@"%@-%@-%@-%@-%@",pm.name,pm.thoroughfare,pm.locality,pm.subLocality,pm.administrativeArea);
        //添加大头针
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        annotation.coordinate = coordinate;
        annotation.title = pm.name;
        [self.mapView addAnnotation:annotation];
    }];
}

#pragma mark - 路径规划
-(void)programRoute
{
    //起点终点经纬度
    CLLocationCoordinate2D startCoordinate = {39.908,116.4};
    CLLocationCoordinate2D endCoordinate = {40.0,116.4};
    //起点终点位置信息
    MKPlacemark *startPM = [[MKPlacemark alloc]initWithCoordinate:startCoordinate addressDictionary:nil];
    MKPlacemark *endPM = [[MKPlacemark alloc]initWithCoordinate:endCoordinate addressDictionary:nil];
    //起点终点节点
    MKMapItem *startItem = [[MKMapItem alloc]initWithPlacemark:startPM];
    MKMapItem *endItem = [[MKMapItem alloc]initWithPlacemark:endPM];
    //路线请求
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc]init];
    request.source = startItem;//起点
    request.destination = endItem;//终点
    //发送请求
    MKDirections *directions = [[MKDirections alloc]initWithRequest:request];
    //保存距离 单位是米
    __block NSInteger sumDistance = 0;
    //计算
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            //取一条路线
            MKRoute *route = [response.routes firstObject];
            
            //关键节点
            for (MKRouteStep *step in route.steps) {
                //添加大头针
                MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
                annotation.coordinate = step.polyline.coordinate;
                annotation.title = step.polyline.title;
                annotation.subtitle = step.polyline.subtitle;
                [self.mapView addAnnotation:annotation];
                
                //添加路线
                [self.mapView addOverlay:step.polyline];
                
                //距离
                sumDistance += step.distance;
            }
        }
    }];
}

#pragma mark - delegate
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    //绘制线
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *render = [[MKPolylineRenderer alloc]initWithOverlay:overlay];
        //线条颜色
        render.strokeColor = [UIColor orangeColor];
        //线条宽度
        render.lineWidth = 5;
        
        return render;
    }
    return nil;
}

#pragma mark - 搜索
/**
 搜索请求对象：MKLocalSearchRequest
 搜索服务类：MKLocalSearch
 */
-(void)mapSearch
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    //创建搜索请求对象
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc]init];
    request.naturalLanguageQuery = @"大学";//搜索关键字
    request.region = self.mapView.region;//搜索范围
    //搜索服务类
    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    //发送搜索
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            for (MKMapItem *item in response.mapItems) {
                MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
                annotation.coordinate = item.placemark.coordinate;
                annotation.title = item.name;
                [self.mapView addAnnotation:annotation];
            }
        }
        
    }];
}

@end
