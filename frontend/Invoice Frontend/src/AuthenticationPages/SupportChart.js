import React from 'react';
import ApexCharts from 'react-apexcharts';
const SupportChart = ({data}) => {
  const options = {
    chart: {
      type: 'area',
      height: 250,
      sparkline: {
        enabled: true
      }
    },
    colors: ["#4680ff"],
    stroke: {
      curve: 'smooth',
      width: 2,
    },
    series: [{
      // data: [0, 20, 10, 45, 30, 55, 20, 30, 0]
      data: data
    }],
    
    tooltip: {
      fixed: {
        enabled: false
      },
      x: {
        show: false
      },
      y: {
        title: {
          formatter: function(seriesName) {
            return ' ';
          }
        }
      },
      marker: {
        show: false
      }
    }
  };

  return (
    <div className="chart-container">
      <ApexCharts 
        options={options} 
        series={options.series} 
        type="area" 
        height={250} 
      />
    </div>
  );
};

export default SupportChart;

