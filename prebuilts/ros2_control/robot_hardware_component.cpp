#include "control/robot_hardware_component.hpp"

#include <chrono>
#include <cmath>
#include <limits>
#include <memory>
#include <vector>
#include <algorithm>

#include "hardware_interface/types/hardware_interface_type_values.hpp"
#include "rclcpp/rclcpp.hpp"

// TODO: Ctrl+F and replace the word robot (turn off case sensitivity) with your robot name

namespace robot_hardware_component
{
    hardware_interface::CallbackReturn RobotHardwareComponent::on_init(
        const hardware_interface::HardwareComponentInterfaceParams & params)
    {
        if (hardware_interface::SystemInterface::on_init(params) != hardware_interface::CallbackReturn::SUCCESS) {
            return hardware_interface::CallbackReturn::ERROR;
        }

        serial_port_ = info_.hardware_parameters["serial_port"];
        baud_rate_ = std::stoi(info_.hardware_parameters["baud_rate"]);
        can_interface_ = info_.hardware_parameters["can_interface"];

        microcontroller_comms_.setup(serial_port_, baud_rate_, 100);
        can_comms_.setup(can_interface_, 1, 2);

        RCLCPP_INFO(rclcpp::get_logger("RobotHardwareComponent"), "Initialized with Serial: %s and CAN: %s", serial_port_.c_str(), can_interface_.c_str());

        return hardware_interface::CallbackReturn::SUCCESS;
    }


    hardware_interface::CallbackReturn RobotHardwareComponent::on_configure(const rclcpp_lifecycle::State &)
    {
        RCLCPP_INFO(rclcpp::get_logger("RobotHardwareComponent"), "Configuring hardware...");
        microcontroller_comms_.connect();
        return hardware_interface::CallbackReturn::SUCCESS;
    }


    hardware_interface::CallbackReturn RobotHardwareComponent::on_cleanup(const rclcpp_lifecycle::State &)
    {
        RCLCPP_INFO(rclcpp::get_logger("RobotHardwareComponent"), "Cleaning up hardware...");
        microcontroller_comms_.disconnect();
        return hardware_interface::CallbackReturn::SUCCESS;
    }


    hardware_interface::CallbackReturn RobotHardwareComponent::on_activate(const rclcpp_lifecycle::State &)
    {
        RCLCPP_INFO(rclcpp::get_logger("RobotHardwareComponent"), "Activating hardware interfaces...");

        microcontroller_comms_.send_stop_command();
        can_comms_.send_stop_command();
        
        // You mostly just want to set internal tracking variables to safe defaults

        return hardware_interface::CallbackReturn::SUCCESS;
    }


    hardware_interface::CallbackReturn RobotHardwareComponent::on_deactivate(const rclcpp_lifecycle::State &)
    {
        RCLCPP_INFO(rclcpp::get_logger("RobotHardwareComponent"), "Deactivating. Sending Emergency Stop.");
        microcontroller_comms_.send_stop_command();
        can_comms_.send_stop_command();
        return hardware_interface::CallbackReturn::SUCCESS;
    }


    std::vector<hardware_interface::StateInterface> RobotHardwareComponent::export_state_interfaces()
    {
        std::vector<hardware_interface::StateInterface> state_interfaces;

        // Claim state interfaces
        state_interfaces.emplace_back(hardware_interface::StateInterface("velocity_example", hardware_interface::HW_IF_VELOCITY, &state_placeholder_vel_));
        state_interfaces.emplace_back(hardware_interface::StateInterface("position_example", hardware_interface::HW_IF_POSITION, &state_placeholder_pos_));

        return state_interfaces;
    }

    std::vector<hardware_interface::CommandInterface> RobotHardwareComponent::export_command_interfaces()
    {
        std::vector<hardware_interface::CommandInterface> command_interfaces;

        // Claim command interfaces
        command_interfaces.emplace_back(hardware_interface::CommandInterface("velocity_example", hardware_interface::HW_IF_VELOCITY, &cmd_placeholder_vel_));
        command_interfaces.emplace_back(hardware_interface::CommandInterface("position_example", hardware_interface::HW_IF_POSITION, &cmd_placeholder_pos_));

        return command_interfaces;
    }


    hardware_interface::return_type RobotHardwareComponent::read(const rclcpp::Time &, const rclcpp::Duration &)
    {
        microcontroller_comms_.read_encoder_values(raw_la_1_ticks_, raw_la_2_ticks_);
        
        // 2. Linear Actuator Sync Check
        // double la_1_meters = raw_la_1_ticks_ / LA_TICKS_PER_METER;
        double la_2_meters = raw_la_2_ticks_ / LA_TICKS_PER_METER;
        
        // if (std::abs(la_1_meters - la_2_meters) > LA_SYNC_TOLERANCE_METERS) {
        //     RCLCPP_FATAL(rclcpp::get_logger("RobotHardwareComponent"), "CRITICAL FAULT: Linear Actuators out of sync by > 20mm! Halting system.");
        //     return hardware_interface::return_type::ERROR; 
        // }

        // 3. Average the LAs for the ROS Controller State
        // state_la_pos_ = (la_1_meters + la_2_meters) / 2.0;
        state_la_pos_ = la_2_meters;

        // 4. Read from CAN bus for wheels
        state_left_wheel_pos_ = can_comms_.get_left_pos();
        state_right_wheel_pos_ = can_comms_.get_right_pos();
        state_left_wheel_vel_ = can_comms_.get_left_vel();
        state_right_wheel_vel_ = can_comms_.get_right_vel();

        return hardware_interface::return_type::OK;
    }


    hardware_interface::return_type RobotHardwareComponent::write(const rclcpp::Time &, const rclcpp::Duration &)
    {
        // Conversion logic here

        microcontroller_comms_.send_commands(var1, var2, var3);
        can_comms_.send_velocities(var1, var2, var3);

        return hardware_interface::return_type::OK;
    }

} // namespace robot_hardware_component

#include "pluginlib/class_list_macros.hpp"
PLUGINLIB_EXPORT_CLASS(robot_hardware_component::RobotHardwareComponent, hardware_interface::SystemInterface)